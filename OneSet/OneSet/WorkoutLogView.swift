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
        ForEach(workoutSections) { section in
          Section {
            ForEach(section.workouts) { workout in
              NavigationLink {
                WorkoutEntryView(workout: workout)
              } label: {
                WorkoutLogRow(workout: workout, history: workoutHistory)
              }
              .buttonStyle(.plain)
              .padding()
              .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
              .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
              .listRowSeparator(.hidden)
              .listRowBackground(Color.clear)
            }
          } header: {
            WorkoutLogSectionHeader(cycle: section.cycle)
          }
        }
      }
    }
    .navigationTitle("Workout Log")
  }

  private var workoutSections: [WorkoutLogSection] {
    var sections: [WorkoutLogSection] = []
    for workout in workouts {
      guard let cycle = WorkoutPlan.focusCycle(containing: workout.dayKey) else {
        preconditionFailure("A workout must have a valid day key")
      }

      if sections.last?.cycle.startDayKey == cycle.startDayKey {
        sections[sections.count - 1].workouts.append(workout)
      } else {
        sections.append(WorkoutLogSection(cycle: cycle, workouts: [workout]))
      }
    }
    return sections
  }

  private var workoutHistory: WorkoutHistory {
    WorkoutHistory(workouts: workouts)
  }
}

private struct WorkoutLogSection: Identifiable {
  let cycle: FocusCycle
  var workouts: [Workout]

  var id: String { cycle.startDayKey }
}

private struct WorkoutLogSectionHeader: View {
  let cycle: FocusCycle

  var body: some View {
    HStack(alignment: .lastTextBaseline) {
      Text("\(cycle.focusedGroup.displayName) Focus")
        .font(.headline)
      if let dateRange = WorkoutDateDisplay.range(
        from: cycle.startDayKey,
        to: cycle.endDayKey
      ) {
        Text(dateRange)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .textCase(nil)
  }
}

private struct WorkoutLogRow: View {
  let workout: Workout
  let history: WorkoutHistory

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(WorkoutDateDisplay.relative(workout.dayKey))
        .font(.headline)

      ForEach(muscleGroups, id: \.self) { muscleGroup in
        VStack(alignment: .leading, spacing: 2) {
          Text(muscleGroup.displayName)
            .font(.subheadline)
            .foregroundStyle(.secondary)

          if let performedSet = workout.performedSet(for: muscleGroup) {
            HStack {
              Text(performedSet.form.displayName)
              Spacer()
              if history.isMaximumPerformance(performedSet) {
                Text("Max")
                  .font(.caption2.bold())
                  .foregroundStyle(.tint)
                  .padding(.horizontal, 6)
                  .padding(.vertical, 2)
                  .background(.tint.opacity(0.12), in: Capsule())
              }
              Text("\(performedSet.reps) x \(performedSet.weightKg) kg")
                .foregroundStyle(.secondary)
            }
          } else {
            Text("Skipped")
              .foregroundStyle(.secondary)
          }
        }
      }

      if !workout.notes.isEmpty {
        Divider()
        Text(workout.notes)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var muscleGroups: [MuscleGroup] {
    guard let muscleGroups = WorkoutPlan.muscleGroupOrder(on: workout.dayKey) else {
      preconditionFailure("A workout must have a valid day key")
    }
    return muscleGroups
  }
}
