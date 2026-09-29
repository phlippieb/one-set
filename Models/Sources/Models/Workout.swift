import Foundation
import SwiftData

@Model
public final class Workout {
  @Attribute(.unique) public private(set) var dayKey: String
  public var notes: String
  @Relationship(deleteRule: .cascade, inverse: \PerformedSet.workout)
  public private(set) var performedSets: [PerformedSet]
  
  public init(
    notes: String = "",
    performedSets: [PerformedSetInput],
    now: Date = .now,
    timeZone: TimeZone = .current
  ) throws(ModelValidationError) {
    guard !performedSets.isEmpty else {
      throw .workoutRequiresPerformedSet
    }
    guard performedSets.count <= MuscleGroup.allCases.count else {
      throw .tooManyPerformedSets
    }
    
    var muscleGroups = Set<MuscleGroup>()
    for input in performedSets where !muscleGroups.insert(input.form.muscleGroup).inserted {
      throw .duplicateMuscleGroup(input.form.muscleGroup)
    }
    
    self.dayKey = WorkoutDayKey.today(now: now, timeZone: timeZone)
    self.notes = notes
    self.performedSets = []
    self.performedSets = performedSets.map { PerformedSet(workout: self, input: $0) }
  }
}
