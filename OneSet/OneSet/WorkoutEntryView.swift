import Models
import SwiftUI

struct WorkoutEntryView: View {
  let workout: Workout?

  init(workout: Workout? = nil) {
    self.workout = workout
  }

  var body: some View {
    Color.clear
      .navigationTitle(workout == nil ? "Log Workout" : "Edit Workout")
  }
}
