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
        dayKey: "2026-09-27",
        notes: "Controlled reps",
        performedSets: [
            try PerformedSetInput(form: .curls, weightKg: 10, reps: 9),
            try PerformedSetInput(form: .skullCrushers, weightKg: 12, reps: 11, shouldRepeat: true),
            try PerformedSetInput(form: .lateralRaises, weightKg: 7, reps: 18),
        ]
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

@Test("Public workouts use today's local day key")
func workoutUsesToday() throws {
    let beforeCreation = WorkoutDayKey.today()
    let workout = try Workout(performedSets: [
        try PerformedSetInput(form: .curls, weightKg: 7, reps: 6),
    ])
    let afterCreation = WorkoutDayKey.today()

    #expect(workout.dayKey == beforeCreation || workout.dayKey == afterCreation)
}

@Test("Workouts reject invalid internal day keys")
func workoutDayKeyValidation() throws {
    let input = try PerformedSetInput(form: .curls, weightKg: 7, reps: 6)

    #expect(throws: ModelValidationError.invalidDayKey("2026-9-21")) {
        try Workout(dayKey: "2026-9-21", performedSets: [input])
    }
}

@Test("Workout mappings expose skips and focus-first set order")
func workoutMappings() throws {
    let workout = try Workout(
        dayKey: "2026-10-05",
        performedSets: [
            try PerformedSetInput(form: .curls, weightKg: 7, reps: 6),
            try PerformedSetInput(form: .skullCrushers, weightKg: 10, reps: 8),
        ]
    )

    #expect(workout.performedSet(for: .biceps)?.form == .curls)
    #expect(!workout.isSkipped(.biceps))
    #expect(workout.isSkipped(.shoulders))
    #expect(workout.performedSetsInPresentationOrder.map(\.form) == [.skullCrushers, .curls])
}

@Test("Workout updates safely persist skipped and unskipped groups")
@MainActor
func workoutUpdate() throws {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
        for: Workout.self,
        PerformedSet.self,
        configurations: configuration
    )
    let context = container.mainContext
    let workout = try Workout(
        dayKey: "2026-10-05",
        performedSets: [
            try PerformedSetInput(form: .curls, weightKg: 7, reps: 6),
            try PerformedSetInput(form: .overheadExtensions, weightKg: 10, reps: 8),
        ]
    )
    context.insert(workout)
    try context.save()

    #expect(throws: ModelValidationError.workoutRequiresPerformedSet) {
        try workout.update(notes: "Invalid", performedSets: [], in: context)
    }
    #expect(workout.performedSets.count == 2)

    try workout.update(
        notes: "Skipped biceps",
        performedSets: [
            try PerformedSetInput(form: .skullCrushers, weightKg: 12, reps: 9),
            try PerformedSetInput(form: .lateralRaises, weightKg: 7, reps: 12),
        ],
        in: context
    )
    try context.save()

    let savedSets = try context.fetch(FetchDescriptor<PerformedSet>())
    #expect(workout.notes == "Skipped biceps")
    #expect(workout.isSkipped(.biceps))
    #expect(workout.performedSet(for: .triceps)?.form == .skullCrushers)
    #expect(workout.performedSet(for: .shoulders)?.form == .lateralRaises)
    #expect(savedSets.count == 2)
    #expect(savedSets.allSatisfy { $0.workout === workout })
}
