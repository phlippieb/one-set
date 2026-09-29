import Testing

@testable import Models

@Test("History sorts workouts and alternates only performed forms")
func workoutHistoryAlternation() throws {
    let history = WorkoutHistory(workouts: [
        try workout(on: "2026-09-23", form: .hammerCurls, weightKg: 10, reps: 8),
        try workout(on: "2026-09-21", form: .curls, weightKg: 7, reps: 6),
        try workout(on: "2026-09-22", form: .skullCrushers, weightKg: 7, reps: 8),
    ])

    #expect(history.workoutsNewestFirst.map(\.dayKey) == ["2026-09-23", "2026-09-22", "2026-09-21"])
    #expect(history.lastPerformedForm(for: .biceps) == .hammerCurls)
    #expect(history.nextForm(for: .biceps) == .curls)
    #expect(history.lastPerformedForm(for: .biceps, before: "2026-09-23") == .curls)
    #expect(history.nextForm(for: .biceps, before: "2026-09-23") == .hammerCurls)
    #expect(history.lastPerformedForm(for: .shoulders) == nil)
    #expect(history.nextForm(for: .shoulders) == .shoulderPresses)
}

@Test("History returns exact-form last and prefilled values")
func workoutHistoryPrefill() throws {
    let olderCurls = try workout(on: "2026-09-21", form: .curls, weightKg: 7, reps: 4)
    let hammerCurls = try workout(on: "2026-09-22", form: .hammerCurls, weightKg: 10, reps: 8)
    let latestCurls = try workout(on: "2026-09-23", form: .curls, weightKg: 10, reps: 9)
    let history = WorkoutHistory(workouts: [hammerCurls, latestCurls, olderCurls])

    #expect(history.lastPerformance(for: .curls) === latestCurls.performedSets[0])
    #expect(history.lastPerformance(for: .curls, before: "2026-09-23") === olderCurls.performedSets[0])
    #expect(history.prefill(for: .curls) == PerformedSetValues(weightKg: 10, reps: 9))
    #expect(history.prefill(for: .curls, before: "2026-09-23") == PerformedSetValues(weightKg: 7, reps: 4))
    #expect(history.prefill(for: .lateralRaises) == PerformedSetValues(weightKg: 7, reps: 6))
}

@Test("Maximum performance prioritizes weight, reps, and latest tied date")
func workoutHistoryMaximum() throws {
    let lighter = try workout(on: "2026-09-21", form: .curls, weightKg: 10, reps: 20)
    let olderMaximum = try workout(on: "2026-09-22", form: .curls, weightKg: 12, reps: 5)
    let lowerReps = try workout(on: "2026-09-23", form: .curls, weightKg: 12, reps: 4)
    let latestMaximum = try workout(on: "2026-09-24", form: .curls, weightKg: 12, reps: 5)
    let history = WorkoutHistory(workouts: [lighter, olderMaximum, lowerReps, latestMaximum])

    #expect(history.maximumPerformance(for: .curls) === latestMaximum.performedSets[0])
    #expect(history.isMaximumPerformance(olderMaximum.performedSets[0]))
    #expect(history.isMaximumPerformance(latestMaximum.performedSets[0]))
    #expect(!history.isMaximumPerformance(lighter.performedSets[0]))
    #expect(!history.isMaximumPerformance(lowerReps.performedSets[0]))
}

@Test("Recommendations apply maintenance, repeat, increment, and weight progression rules")
func workoutHistoryRecommendations() throws {
    let noHistory = WorkoutHistory(workouts: [])
    #expect(noHistory.recommendation(for: .overheadExtensions, on: "2026-10-05") == PerformedSetValues(weightKg: 7, reps: 8))

    let maintenance = WorkoutHistory(workouts: [
        try workout(on: "2026-10-04", form: .curls, weightKg: 10, reps: 9),
    ])
    #expect(maintenance.recommendation(for: .curls, on: "2026-10-05") == PerformedSetValues(weightKg: 10, reps: 9))

    let repeatHistory = WorkoutHistory(workouts: [
        try workout(on: "2026-09-29", form: .curls, weightKg: 10, reps: 8, shouldRepeat: true),
    ])
    #expect(repeatHistory.recommendation(for: .curls, on: "2026-09-30") == PerformedSetValues(weightKg: 10, reps: 8))

    let incrementHistory = WorkoutHistory(workouts: [
        try workout(on: "2026-09-29", form: .curls, weightKg: 10, reps: 8),
    ])
    #expect(incrementHistory.recommendation(for: .curls, on: "2026-09-30") == PerformedSetValues(weightKg: 10, reps: 9))

    let raiseWeightHistory = WorkoutHistory(workouts: [
        try workout(on: "2026-09-29", form: .curls, weightKg: 10, reps: 13),
    ])
    #expect(raiseWeightHistory.recommendation(for: .curls, on: "2026-09-30") == PerformedSetValues(weightKg: 12, reps: 6))

    let highestWeightHistory = WorkoutHistory(workouts: [
        try workout(on: "2026-09-29", form: .curls, weightKg: 15, reps: 13),
    ])
    #expect(highestWeightHistory.recommendation(for: .curls, on: "2026-09-30") == PerformedSetValues(weightKg: 15, reps: 13))

    let laterSavedDayHistory = WorkoutHistory(workouts: [
        try workout(on: "2026-10-01", form: .curls, weightKg: 12, reps: 10),
    ])
    #expect(laterSavedDayHistory.recommendation(for: .curls, on: "2026-09-30") == PerformedSetValues(weightKg: 12, reps: 11))
}

@Test("Focus-cycle progress distinguishes logged, missed, today, and upcoming days")
func workoutHistoryProgress() throws {
    let history = WorkoutHistory(workouts: [
        try workout(on: "2026-09-21", form: .curls, weightKg: 7, reps: 6),
        try workout(on: "2026-09-23", form: .skullCrushers, weightKg: 7, reps: 8),
        try workout(on: "2026-09-25", form: .lateralRaises, weightKg: 7, reps: 6),
    ])
    let progress = history.focusCycleProgress(todayDayKey: "2026-09-25")

    #expect(progress.count == 14)
    #expect(progress[0] == FocusCycle.Day(dayKey: "2026-09-21", state: .logged))
    #expect(progress[1] == FocusCycle.Day(dayKey: "2026-09-22", state: .missed))
    #expect(progress[2] == FocusCycle.Day(dayKey: "2026-09-23", state: .logged))
    #expect(progress[4] == FocusCycle.Day(dayKey: "2026-09-25", state: .today(isLogged: true)))
    #expect(progress[5] == FocusCycle.Day(dayKey: "2026-09-26", state: .upcoming))
    #expect(progress[13].dayKey == "2026-10-04")

    let unloggedToday = WorkoutHistory(workouts: Array(history.workoutsNewestFirst.dropFirst()))
    #expect(unloggedToday.focusCycleProgress(todayDayKey: "2026-09-25")[4].state == .today(isLogged: false))
}

private func workout(
    on dayKey: String,
    form: ExerciseForm,
    weightKg: Int,
    reps: Int,
    shouldRepeat: Bool = false
) throws -> Workout {
    try Workout(
        dayKey: dayKey,
        performedSets: [
            try PerformedSetInput(
                form: form,
                weightKg: weightKg,
                reps: reps,
                shouldRepeat: shouldRepeat
            ),
        ]
    )
}
