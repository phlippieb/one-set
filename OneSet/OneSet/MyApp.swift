import Models
import SwiftData
import SwiftUI

@main struct MyApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            let modelContainer = try ModelContainer(
                for: Workout.self,
                PerformedSet.self
            )
            try DummyDataSeeder.seedIfNeeded(into: modelContainer)
            self.modelContainer = modelContainer
        } catch {
            fatalError("Unable to configure the model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(modelContainer)
    }
}
