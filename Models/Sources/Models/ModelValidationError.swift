public enum ModelValidationError: Error, Equatable, Sendable {
  case workoutRequiresPerformedSet
  case tooManyPerformedSets
  case duplicateMuscleGroup(MuscleGroup)
  case invalidWeightKg(Int)
  case invalidReps(Int)
}
