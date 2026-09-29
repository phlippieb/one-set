public enum ModelValidationError: Error, Equatable, Sendable {
  case invalidDayKey(String)
  case workoutRequiresPerformedSet
  case tooManyPerformedSets
  case duplicateMuscleGroup(MuscleGroup)
  case invalidWeightKg(Int)
  case invalidReps(Int)
}
