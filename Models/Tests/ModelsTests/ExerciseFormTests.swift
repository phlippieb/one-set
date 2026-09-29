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
