import Foundation
import Models
import SwiftData
import SwiftUI

struct HomeView: View {
  @Query private var workouts: [Workout]

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 16) {
          if let cycle = WorkoutPlan.focusCycle(containing: todayDayKey) {
            FocusCycleView(cycle: cycle, progress: cycleProgress)
          }
          Spacer(minLength: 12)

          HStack(alignment: .top, spacing: 12) {
            NavigationLink {
              WorkoutEntryView()
            } label: {
              HomeActionCard(
                title: isTodayLogged
                  ? "Today's workout is logged"
                  : "Log Workout",
                systemImage: isTodayLogged
                  ? "checkmark"
                  : "plus",
                isPrimary: true
              )
              .opacity(isTodayLogged ? 0.5 : 1)
            }
            .disabled(isTodayLogged)
            .frame(maxWidth: .infinity)

            NavigationLink {
              WorkoutLogView()
            } label: {
              HomeActionCard(
                title: "Workout Log",
                systemImage: "list.bullet",
                isPrimary: false
              )
            }
            .frame(maxWidth: .infinity)
          }
          .buttonStyle(.plain)
          Spacer(minLength: 12)

          Text("Exercises")
            .font(.title2.bold())
            .padding(.top, 8)

          LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
          ) {
            ForEach(ExerciseForm.allCases) { form in
              FormSummaryCard(
                form: form,
                lastPerformance: workoutHistory.lastPerformance(for: form),
                maximumPerformance: workoutHistory.maximumPerformance(for: form)
              )
            }
          }
        }
        .padding()
      }
      .navigationTitle("One Set")
    }
  }

  private var todayDayKey: String {
    WorkoutDayKey.today()
  }

  private var cycleProgress: [FocusCycle.Day] {
    workoutHistory.focusCycleProgress(todayDayKey: todayDayKey)
  }

  private var workoutHistory: WorkoutHistory {
    WorkoutHistory(workouts: workouts)
  }

  private var isTodayLogged: Bool {
    workouts.contains { $0.dayKey == todayDayKey }
  }
}

private struct FocusCycleView: View {
  let cycle: FocusCycle
  let progress: [FocusCycle.Day]

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .lastTextBaseline) {
        Text("\(cycle.focusedGroup.displayName) Focus")
          .font(.title.bold())
        if let startDayComponents = WorkoutDayKey.dateComponents(from: cycle.startDayKey),
          let endDayComponents = WorkoutDayKey.dateComponents(from: cycle.endDayKey),
          let startDay = startDayComponents.calendar?.date(from: startDayComponents),
          let endDay = endDayComponents.calendar?.date(from: endDayComponents)
        {
          Text(formattedDateRange(from: startDay, to: endDay))
            .font(.footnote)
            .foregroundStyle(.secondary)
          Spacer()
        }
      }

      HStack(spacing: 0) {
        ForEach(progress) { day in
          FocusCycleDayView(day: day)
            .frame(maxWidth: .infinity)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct HomeActionCard: View {
  let title: String
  let systemImage: String
  let isPrimary: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Image(systemName: systemImage)
        .font(.headline)
        .foregroundStyle(.white)
        .frame(width: 36, height: 36)
        .background(iconBackground, in: Circle())

      Spacer(minLength: 8)

      Text(title)
        .font(.headline)
        .multilineTextAlignment(.leading)
        .foregroundStyle(foregroundColor)
    }
    .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
    .padding()
    .background(backgroundColor, in: RoundedRectangle(cornerRadius: 16))
    .contentShape(RoundedRectangle(cornerRadius: 16))
  }

  private var backgroundColor: Color {
    isPrimary ? .accentColor : .secondary.opacity(0.12)
  }

  private var foregroundColor: Color {
    isPrimary ? .white : .primary
  }

  private var iconBackground: Color {
    isPrimary ? .white.opacity(0.22) : .accentColor
  }
}

private struct FormSummaryCard: View {
  let form: ExerciseForm
  let lastPerformance: PerformedSet?
  let maximumPerformance: PerformedSet?

  var body: some View {
    GroupBox {
      VStack(alignment: .leading) {
        Text(form.displayName)
          .font(.headline)
        Text(form.muscleGroup.displayName)
          .font(.subheadline)
        Spacer(minLength: 12)
        if let lastPerformance, let maximumPerformance {
          performanceRow(title: "Last", performedSet: lastPerformance)
          Divider()
          performanceRow(title: "Max", performedSet: maximumPerformance)
        } else {
          Text("No workouts yet")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
    .frame(maxWidth: .infinity)
  }

  private func performanceRow(title: String, performedSet: PerformedSet) -> some View {
    VStack(alignment: .leading) {
      Text(title)
        .foregroundStyle(.secondary)
      Text("\(performedSet.reps) x \(performedSet.weightKg) kg")
      Text(formattedDate(performedSet.workout.dayKey))
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

private struct FocusCycleDayView: View {
  let day: FocusCycle.Day

  var body: some View {
    ZStack {
      switch day.state {
      case .logged:
        Circle()
          .fill(.primary)
      case .missed:
        Circle()
          .stroke(.secondary, lineWidth: 1)
        Rectangle()
          .fill(.secondary)
          .frame(width: 18, height: 1)
          .rotationEffect(.degrees(-45))
      case .today(isLogged: true):
        Circle()
          .fill(.tint)
      case .today(isLogged: false):
        Circle()
          .stroke(.tint, lineWidth: 2)
      case .upcoming:
        Circle()
          .stroke(.tertiary, lineWidth: 1)
      }
    }
    .frame(width: 16, height: 16)
    .accessibilityLabel(accessibilityLabel)
  }

  private var accessibilityLabel: String {
    let state: String
    switch day.state {
    case .logged:
      state = "logged"
    case .missed:
      state = "missed"
    case .today(isLogged: true):
      state = "today, logged"
    case .today(isLogged: false):
      state = "today, not logged"
    case .upcoming:
      state = "upcoming"
    }
    return "\(day.dayKey), \(state)"
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

private func formattedDateRange(from startDay: Date, to endDay: Date) -> String {
  let formatter = DateIntervalFormatter()
  formatter.dateTemplate = "dMMM"
  return formatter.string(from: startDay, to: endDay)
}

#Preview {
  HomeView()
    .modelContainer(for: [Workout.self, PerformedSet.self], inMemory: true)
}
