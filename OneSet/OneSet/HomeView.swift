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
                        VStack(alignment: .leading, spacing: 16) {
                            Text("\(cycle.focusedGroup.displayName) Focus")
                                .font(.title.bold())

                            HStack(spacing: 0) {
                                ForEach(cycleProgress) { day in
                                    FocusCycleDayView(day: day)
                                        .frame(maxWidth: .infinity)
                                }
                            }

                            Text(
                                "Next: \(cycle.nextFocusedGroup.displayName) Focus starts \(formattedDate(cycle.nextStartDayKey))"
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text("Exercises")
                        .font(.title2.bold())
                        .padding(.top, 8)

                    ForEach(ExerciseForm.allCases) { form in
                        FormSummaryCard(
                            form: form,
                            lastPerformance: workoutHistory.lastPerformance(for: form),
                            maximumPerformance: workoutHistory.maximumPerformance(for: form)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
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
}

private struct FormSummaryCard: View {
    let form: ExerciseForm
    let lastPerformance: PerformedSet?
    let maximumPerformance: PerformedSet?

    var body: some View {
        GroupBox {
            if let lastPerformance, let maximumPerformance {
                VStack(spacing: 12) {
                    performanceRow(title: "Last", performedSet: lastPerformance)
                    Divider()
                    performanceRow(title: "Max", performedSet: maximumPerformance)
                }
            } else {
                Text("No workouts yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } label: {
            Text(form.displayName)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
    }

    private func performanceRow(title: String, performedSet: PerformedSet) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(performedSet.reps) reps at \(performedSet.weightKg) kg")
                Text(formattedDate(performedSet.workout.dayKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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

#Preview {
    HomeView()
        .modelContainer(for: [Workout.self, PerformedSet.self], inMemory: true)
}
