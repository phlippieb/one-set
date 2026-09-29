import Models
import SwiftData
import SwiftUI

struct HomeView: View {
    @Query private var workouts: [Workout]

    var body: some View {
        NavigationStack {
            ScrollView {
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
                    .padding()
                }
            }
            .navigationTitle("Home")
        }
    }

    private var todayDayKey: String {
        WorkoutDayKey.today()
    }

    private var cycleProgress: [FocusCycle.Day] {
        WorkoutHistory(workouts: workouts).focusCycleProgress(todayDayKey: todayDayKey)
    }

    private func formattedDate(_ dayKey: String) -> String {
        guard let components = WorkoutDayKey.dateComponents(from: dayKey),
              let date = components.calendar?.date(from: components)
        else {
            return dayKey
        }
        return date.formatted(date: .long, time: .omitted)
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

#Preview {
    HomeView()
        .modelContainer(for: [Workout.self, PerformedSet.self], inMemory: true)
}
