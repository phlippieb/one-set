import SwiftData

@Model
public final class PerformedSet {
  public private(set) var formID: String
  public private(set) var weightKg: Int
  public private(set) var reps: Int
  public var shouldRepeat: Bool
  private(set) var workoutRelationship: Workout?

  // SwiftData clears the inverse before retained references disappear during cascade deletion.
  public var workout: Workout? { workoutRelationship }
  
  public var form: ExerciseForm {
    // All writes pass through typed, validated APIs.
    ExerciseForm(rawValue: formID)!
  }
  
  init(workout: Workout, input: PerformedSetInput) {
    self.workoutRelationship = workout
    self.formID = input.form.id
    self.weightKg = input.weightKg
    self.reps = input.reps
    self.shouldRepeat = input.shouldRepeat
  }
  
  public func update(with input: PerformedSetInput) throws(ModelValidationError) {
    guard let workoutRelationship else {
      preconditionFailure("A deleted performed set cannot be updated")
    }
    if input.form.muscleGroup != form.muscleGroup,
       workoutRelationship.performedSets.contains(where: {
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
