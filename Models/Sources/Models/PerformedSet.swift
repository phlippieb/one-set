import SwiftData

@Model
public final class PerformedSet {
  public private(set) var formID: String
  public private(set) var weightKg: Int
  public private(set) var reps: Int
  public var shouldRepeat: Bool
  public private(set) var workout: Workout
  
  public var form: ExerciseForm {
    // All writes pass through typed, validated APIs.
    ExerciseForm(rawValue: formID)!
  }
  
  init(workout: Workout, input: PerformedSetInput) {
    self.workout = workout
    self.formID = input.form.id
    self.weightKg = input.weightKg
    self.reps = input.reps
    self.shouldRepeat = input.shouldRepeat
  }
  
  public func update(with input: PerformedSetInput) throws(ModelValidationError) {
    if input.form.muscleGroup != form.muscleGroup,
       workout.performedSets.contains(where: {
         $0 !== self && $0.form.muscleGroup == input.form.muscleGroup
       }) {
      throw .duplicateMuscleGroup(input.form.muscleGroup)
    }
    
    formID = input.form.id
    weightKg = input.weightKg
    reps = input.reps
    shouldRepeat = input.shouldRepeat
  }
}
