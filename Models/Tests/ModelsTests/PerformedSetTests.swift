import Testing

@testable import Models

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
