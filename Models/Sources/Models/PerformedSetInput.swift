public struct PerformedSetInput: Equatable, Sendable {
  public let form: ExerciseForm
  public let weightKg: Int
  public let reps: Int
  public let shouldRepeat: Bool
  
  public init(
    form: ExerciseForm,
    weightKg: Int,
    reps: Int,
    shouldRepeat: Bool = false
  ) throws(ModelValidationError) {
    guard WorkoutPlan.availableWeightsKg.contains(weightKg) else {
      throw .invalidWeightKg(weightKg)
    }
    guard reps >= 1 else {
      throw .invalidReps(reps)
    }
    
    self.form = form
    self.weightKg = weightKg
    self.reps = reps
    self.shouldRepeat = shouldRepeat
  }
}
