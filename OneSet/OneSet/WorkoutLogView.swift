import Foundation
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
              WorkoutLogRow(workout: workout, history: workoutHistory)
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
      if let startDay = date(from: cycle.startDayKey),
        let endDay = date(from: cycle.endDayKey)
      {
        Text(formattedDateRange(from: startDay, to: endDay))
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
      Text(formattedDate(workout.dayKey))
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

private func formattedDate(_ dayKey: String, relativeTo referenceDate: Date = .now) -> String {
  let calendar = displayCalendar()
  guard let date = date(from: dayKey, calendar: calendar) else {
    return dayKey
  }

  if calendar.isDate(date, inSameDayAs: referenceDate) {
    return "Today"
  }
  if let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDate),
    calendar.isDate(date, inSameDayAs: yesterday)
  {
    return "Yesterday"
  }

  let formatter = DateFormatter()
  formatter.calendar = calendar
  formatter.locale = .current
  formatter.timeZone = calendar.timeZone
  if calendar.isDate(date, equalTo: referenceDate, toGranularity: .weekOfYear) {
    formatter.dateFormat = "EEEE"
    return formatter.string(from: date)
  }
  if let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: referenceDate),
    calendar.isDate(date, equalTo: previousWeek, toGranularity: .weekOfYear)
  {
    formatter.dateFormat = "EEEE"
    return "Last \(formatter.string(from: date))"
  }

  let isSameYear = calendar.component(.year, from: date)
    == calendar.component(.year, from: referenceDate)
  formatter.dateFormat = isSameYear ? "EEEE d MMM" : "EEEE d MMM yyyy"
  return formatter.string(from: date)
}

private func formattedDateRange(from startDay: Date, to endDay: Date) -> String {
  let formatter = DateIntervalFormatter()
  formatter.dateTemplate = "dMMM"
  return formatter.string(from: startDay, to: endDay)
}

private func date(from dayKey: String, calendar: Calendar = displayCalendar()) -> Date? {
  guard let components = WorkoutDayKey.dateComponents(from: dayKey) else {
    return nil
  }
  var localComponents = components
  localComponents.calendar = calendar
  localComponents.timeZone = calendar.timeZone
  return calendar.date(from: localComponents)
}

private func displayCalendar() -> Calendar {
  var calendar = Calendar(identifier: .gregorian)
  calendar.locale = .current
  calendar.timeZone = .current
  return calendar
}
