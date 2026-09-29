import Models
import SwiftData

enum DummyDataSeeder {
    @MainActor static func seedIfNeeded(into container: ModelContainer) throws {
        let context = container.mainContext
        guard try context.fetchCount(FetchDescriptor<Workout>()) == 0 else {
            return
        }

        for workout in try Workout.dummyData() {
            context.insert(workout)
        }
        try context.save()
    }
}
