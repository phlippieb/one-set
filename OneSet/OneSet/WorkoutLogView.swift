import Models
import SwiftData
import SwiftUI

struct WorkoutLogView: View {
  @Query(sort: \Workout.dayKey, order: .reverse) private var workouts: [Workout]

  var body: some View {
    List {
      if workouts.isEmpty {
        ContentUnavailableView("No Workouts", systemImage: "dumbbell")
      } else {
        ForEach(workouts) { workout in
          WorkoutLogRow(workout: workout)
        }
      }
    }
    .navigationTitle("Workout Log")
  }
}

private struct WorkoutLogRow: View {
  let workout: Workout

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(formattedDate(workout.dayKey))
        .font(.headline)

      ForEach(workout.performedSetsInPresentationOrder) { performedSet in
        HStack {
          Text(performedSet.form.displayName)
          Spacer()
          Text("\(performedSet.reps) x \(performedSet.weightKg) kg")
            .foregroundStyle(.secondary)
        }
      }
    }
  }
}

private func formattedDate(_ dayKey: String) -> String {
  guard let components = WorkoutDayKey.dateComponents(from: dayKey),
    let date = components.calendar?.date(from: components)
  else {
    return dayKey
  }
  return date.formatted(date: .long, time: .omitted)
}
