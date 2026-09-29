import Foundation
import SwiftData

@Model
public final class Workout {
  @Attribute(.unique) public private(set) var dayKey: String
  public var notes: String
  @Relationship(deleteRule: .cascade, inverse: \PerformedSet.workoutRelationship)
  public private(set) var performedSets: [PerformedSet] = []
  
  public convenience init(
    notes: String = "",
    performedSets: [PerformedSetInput]
  ) throws(ModelValidationError) {
    try self.init(
      dayKey: WorkoutDayKey.today(),
      notes: notes,
      performedSets: performedSets
    )
  }

  init(
    dayKey: String,
    notes: String = "",
    performedSets: [PerformedSetInput]
  ) throws(ModelValidationError) {
    guard WorkoutDayKey.isValid(dayKey) else {
      throw .invalidDayKey(dayKey)
    }
    try Self.validate(performedSets)

    self.dayKey = dayKey
    self.notes = notes
    self.performedSets = performedSets.map { PerformedSet(workout: self, input: $0) }
  }
}

extension Workout {
  public func performedSet(for muscleGroup: MuscleGroup) -> PerformedSet? {
    performedSets.first { $0.form.muscleGroup == muscleGroup }
  }

  public func isSkipped(_ muscleGroup: MuscleGroup) -> Bool {
    performedSet(for: muscleGroup) == nil
  }

  public var performedSetsInPresentationOrder: [PerformedSet] {
    guard let muscleGroups = WorkoutPlan.muscleGroupOrder(on: dayKey) else {
      preconditionFailure("A workout must have a valid day key")
    }
    return muscleGroups.compactMap(performedSet(for:))
  }

  public func update(
    notes: String,
    performedSets inputs: [PerformedSetInput],
    in context: ModelContext
  ) throws(ModelValidationError) {
    try Self.validate(inputs)

    let previousSets = performedSets
    var updatedSets: [PerformedSet] = []
    for input in inputs {
      if let existingSet = performedSet(for: input.form.muscleGroup) {
        try existingSet.update(with: input)
        updatedSets.append(existingSet)
      } else {
        let newSet = PerformedSet(workout: self, input: input)
        context.insert(newSet)
        updatedSets.append(newSet)
      }
    }

    self.notes = notes
    performedSets = updatedSets
    for previousSet in previousSets where !updatedSets.contains(where: { $0 === previousSet }) {
      context.delete(previousSet)
    }
  }

  private static func validate(
    _ performedSets: [PerformedSetInput]
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
  }
}
