import Foundation
import SwiftData
import Testing

@testable import Models

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
