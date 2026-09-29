import Testing

@testable import Models

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
