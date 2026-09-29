import Foundation
import SwiftData
import Testing

@testable import Models

@Test("Exercise forms expose stable plan metadata", arguments: [
    (ExerciseForm.curls, "biceps.curls", MuscleGroup.biceps, 6...12),
    (.hammerCurls, "biceps.hammer-curls", .biceps, 6...12),
    (.overheadExtensions, "triceps.overhead-extensions", .triceps, 8...15),
    (.skullCrushers, "triceps.skull-crushers", .triceps, 8...15),
    (.shoulderPresses, "shoulders.shoulder-presses", .shoulders, 6...12),
    (.lateralRaises, "shoulders.lateral-raises", .shoulders, 6...20),
])
func exerciseFormMetadata(
    form: ExerciseForm,
    id: String,
    muscleGroup: MuscleGroup,
    repRange: ClosedRange<Int>
) {
    #expect(form.id == id)
    #expect(form.muscleGroup == muscleGroup)
    #expect(form.repRange == repRange)
    #expect(form.repFloor == repRange.lowerBound)
    #expect(form.repCeiling == repRange.upperBound)
    #expect(muscleGroup.forms.contains(form))
}

@Test("Day keys use the Gregorian local calendar")
func dayKeys() {
    let epoch = Date(timeIntervalSince1970: 0)

    #expect(WorkoutDayKey.today(now: epoch, timeZone: TimeZone(secondsFromGMT: 0)!) == "1970-01-01")
    #expect(WorkoutDayKey.today(now: epoch, timeZone: TimeZone(secondsFromGMT: -8 * 60 * 60)!) == "1969-12-31")
    #expect(WorkoutDayKey.isValid("2024-02-29"))
    #expect(!WorkoutDayKey.isValid("2023-02-29"))
    #expect(!WorkoutDayKey.isValid("2026-9-21"))
}

@Test("Performed set inputs reject unsupported values")
func performedSetInputValidation() throws {
    #expect(throws: ModelValidationError.invalidWeightKg(8)) {
        try PerformedSetInput(form: .curls, weightKg: 8, reps: 6)
    }
    #expect(throws: ModelValidationError.invalidReps(0)) {
        try PerformedSetInput(form: .curls, weightKg: 7, reps: 0)
    }

    _ = try PerformedSetInput(form: .curls, weightKg: 7, reps: 1)
    _ = try PerformedSetInput(form: .curls, weightKg: 15, reps: 100)
}

@Test("Workouts require one to three distinct muscle groups")
func workoutSetValidation() throws {
    let curls = try PerformedSetInput(form: .curls, weightKg: 7, reps: 6)
    let hammerCurls = try PerformedSetInput(form: .hammerCurls, weightKg: 10, reps: 8)
    let triceps = try PerformedSetInput(form: .overheadExtensions, weightKg: 7, reps: 8)
    let shoulders = try PerformedSetInput(form: .shoulderPresses, weightKg: 7, reps: 6)

    #expect(throws: ModelValidationError.workoutRequiresPerformedSet) {
        try Workout(performedSets: [])
    }
    #expect(throws: ModelValidationError.tooManyPerformedSets) {
        try Workout(performedSets: [curls, hammerCurls, triceps, shoulders])
    }
    #expect(throws: ModelValidationError.duplicateMuscleGroup(.biceps)) {
        try Workout(performedSets: [curls, hammerCurls])
    }
}

@Test("Workout graph persists and cascade deletes its sets")
@MainActor
func workoutPersistence() throws {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
        for: Workout.self,
        PerformedSet.self,
        configurations: configuration
    )
    let context = container.mainContext
    let workout = try Workout(
        notes: "Controlled reps",
        performedSets: [
            try PerformedSetInput(form: .curls, weightKg: 10, reps: 9),
            try PerformedSetInput(form: .skullCrushers, weightKg: 12, reps: 11, shouldRepeat: true),
            try PerformedSetInput(form: .lateralRaises, weightKg: 7, reps: 18),
        ],
        now: Date(timeIntervalSince1970: 1_790_029_800),
        timeZone: TimeZone(secondsFromGMT: 2 * 60 * 60)!
    )

    context.insert(workout)
    try context.save()

    let savedWorkouts = try context.fetch(FetchDescriptor<Workout>())
    let savedSets = try context.fetch(FetchDescriptor<PerformedSet>())
    #expect(savedWorkouts.count == 1)
    #expect(savedWorkouts.first?.notes == "Controlled reps")
    #expect(savedWorkouts.first?.performedSets.count == 3)
    #expect(Set(savedSets.map(\.form)) == [.curls, .skullCrushers, .lateralRaises])
    #expect(savedSets.first(where: { $0.form == .skullCrushers })?.shouldRepeat == true)

    context.delete(workout)
    try context.save()

    #expect(try context.fetchCount(FetchDescriptor<Workout>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<PerformedSet>()) == 0)
}

@Test("A performed set can be updated without creating duplicate groups")
func performedSetUpdate() throws {
    let workout = try Workout(performedSets: [
        try PerformedSetInput(form: .curls, weightKg: 7, reps: 6),
        try PerformedSetInput(form: .overheadExtensions, weightKg: 10, reps: 8),
    ])
    let biceps = workout.performedSets.first(where: { $0.form.muscleGroup == .biceps })!

    try biceps.update(with: PerformedSetInput(form: .hammerCurls, weightKg: 10, reps: 7))
    #expect(biceps.form == .hammerCurls)
    #expect(biceps.weightKg == 10)
    #expect(biceps.reps == 7)

    #expect(throws: ModelValidationError.duplicateMuscleGroup(.triceps)) {
        try biceps.update(with: PerformedSetInput(form: .skullCrushers, weightKg: 10, reps: 8))
    }
}
