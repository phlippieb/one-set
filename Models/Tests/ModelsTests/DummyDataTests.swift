import SwiftData
import Testing
@testable import Models

struct DummyDataTests {
  @Test func dummyDataCoversTheWorkoutHistoryStates() throws {
    let workouts = try Workout.dummyData()

    #expect(workouts.count == 7)
    #expect(Set(workouts.map(\.dayKey)).count == workouts.count)
    #expect(Set(workouts.flatMap(\.performedSets).map(\.form)) == Set(ExerciseForm.allCases))
    #expect(workouts.contains { $0.performedSets.count < MuscleGroup.allCases.count })
    #expect(workouts.flatMap(\.performedSets).contains { $0.shouldRepeat })
    #expect(workouts.contains { !$0.notes.isEmpty })
  }

  @Test @MainActor func dummyDataPersistsAsACompleteGraph() throws {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: Workout.self,
      PerformedSet.self,
      configurations: configuration
    )
    let context = container.mainContext

    for workout in try Workout.dummyData() {
      context.insert(workout)
    }
    try context.save()

    #expect(try context.fetchCount(FetchDescriptor<Workout>()) == 7)
    #expect(try context.fetchCount(FetchDescriptor<PerformedSet>()) == 19)
  }
}
