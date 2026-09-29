public struct WorkoutHistory {
  private let workouts: [Workout]

  public init(workouts: [Workout]) {
    self.workouts = workouts
  }

  public var workoutsNewestFirst: [Workout] {
    workouts.sorted { $0.dayKey > $1.dayKey }
  }

  public func lastPerformedForm(for muscleGroup: MuscleGroup) -> ExerciseForm? {
    lastPerformedForm(for: muscleGroup, before: nil)
  }

  public func lastPerformedForm(
    for muscleGroup: MuscleGroup,
    before dayKey: String
  ) -> ExerciseForm? {
    precondition(WorkoutDayKey.isValid(dayKey), "A history cutoff must be a valid day key")
    return lastPerformedForm(for: muscleGroup, before: dayKey as String?)
  }

  public func nextForm(for muscleGroup: MuscleGroup) -> ExerciseForm {
    nextForm(after: lastPerformedForm(for: muscleGroup), in: muscleGroup)
  }

  public func nextForm(
    for muscleGroup: MuscleGroup,
    before dayKey: String
  ) -> ExerciseForm {
    nextForm(after: lastPerformedForm(for: muscleGroup, before: dayKey), in: muscleGroup)
  }

  public func lastPerformance(for form: ExerciseForm) -> PerformedSet? {
    lastPerformance(for: form, before: nil)
  }

  public func lastPerformance(
    for form: ExerciseForm,
    before dayKey: String
  ) -> PerformedSet? {
    precondition(WorkoutDayKey.isValid(dayKey), "A history cutoff must be a valid day key")
    return lastPerformance(for: form, before: dayKey as String?)
  }

  public func maximumPerformance(for form: ExerciseForm) -> PerformedSet? {
    workouts
      .flatMap(\.performedSets)
      .filter { $0.form == form }
      .sorted(by: isHigherPerformance)
      .first
  }

  public func isMaximumPerformance(_ performedSet: PerformedSet) -> Bool {
    guard let maximum = maximumPerformance(for: performedSet.form) else {
      return false
    }
    return performedSet.weightKg == maximum.weightKg && performedSet.reps == maximum.reps
  }

  public func prefill(for form: ExerciseForm) -> PerformedSetValues {
    guard let previous = lastPerformance(for: form) else {
      return defaultValues(for: form)
    }
    return values(from: previous)
  }

  public func prefill(
    for form: ExerciseForm,
    before dayKey: String
  ) -> PerformedSetValues {
    precondition(WorkoutDayKey.isValid(dayKey), "A prefill cutoff must be a valid day key")
    guard let previous = lastPerformance(for: form, before: dayKey) else {
      return defaultValues(for: form)
    }
    return values(from: previous)
  }

  public func recommendation(
    for form: ExerciseForm,
    on dayKey: String
  ) -> PerformedSetValues {
    precondition(WorkoutDayKey.isValid(dayKey), "A recommendation date must be a valid day key")
    guard let previous = lastPerformance(for: form) else {
      return defaultValues(for: form)
    }

    let previousValues = values(from: previous)
    guard WorkoutPlan.focusCycle(containing: dayKey)?.focusedGroup == form.muscleGroup,
          !previous.shouldRepeat
            else {
      return previousValues
    }

    guard previous.reps >= form.repCeiling else {
      return PerformedSetValues(weightKg: previous.weightKg, reps: previous.reps + 1)
    }

    guard let weightIndex = WorkoutPlan.availableWeightsKg.firstIndex(of: previous.weightKg),
          weightIndex < WorkoutPlan.availableWeightsKg.index(before: WorkoutPlan.availableWeightsKg.endIndex)
            else {
      return previousValues
    }

    return PerformedSetValues(
      weightKg: WorkoutPlan.availableWeightsKg[weightIndex + 1],
      reps: form.repFloor
    )
  }

  public func focusCycleProgress(todayDayKey: String = WorkoutDayKey.today()) -> [FocusCycle.Day] {
    guard let cycle = WorkoutPlan.focusCycle(containing: todayDayKey) else {
      preconditionFailure("Focus-cycle progress requires a valid day key")
    }
    let loggedDayKeys = Set(workouts.map(\.dayKey))

    return (0..<WorkoutPlan.focusCycleDurationDays).map { dayOffset in
      let dayKey = WorkoutDayKey.adding(days: dayOffset, to: cycle.startDayKey)!
      let isLogged = loggedDayKeys.contains(dayKey)
      let state: FocusCycle.Day.State
      if dayKey == todayDayKey {
        state = .today(isLogged: isLogged)
      } else if dayKey < todayDayKey {
        state = isLogged ? .logged : .missed
      } else {
        state = .upcoming
      }
      return FocusCycle.Day(dayKey: dayKey, state: state)
    }
  }

  private func lastPerformedForm(
    for muscleGroup: MuscleGroup,
    before dayKey: String?
  ) -> ExerciseForm? {
    matchingWorkouts(before: dayKey)
      .lazy
      .compactMap { $0.performedSet(for: muscleGroup)?.form }
      .first
  }

  private func lastPerformance(
    for form: ExerciseForm,
    before dayKey: String?
  ) -> PerformedSet? {
    matchingWorkouts(before: dayKey)
      .lazy
      .compactMap { workout in
        workout.performedSets.first { $0.form == form }
      }
      .first
  }

  private func matchingWorkouts(before dayKey: String?) -> [Workout] {
    workoutsNewestFirst.filter { workout in
      dayKey.map { workout.dayKey < $0 } ?? true
    }
  }

  private func nextForm(
    after form: ExerciseForm?,
    in muscleGroup: MuscleGroup
  ) -> ExerciseForm {
    let forms = muscleGroup.forms
    guard let form,
          let index = forms.firstIndex(of: form)
            else {
      return forms[0]
    }
    return forms[(index + 1) % forms.count]
  }

  private func isHigherPerformance(_ lhs: PerformedSet, _ rhs: PerformedSet) -> Bool {
    if lhs.weightKg != rhs.weightKg {
      return lhs.weightKg > rhs.weightKg
    }
    if lhs.reps != rhs.reps {
      return lhs.reps > rhs.reps
    }
    return lhs.workout.dayKey > rhs.workout.dayKey
  }

  private func defaultValues(for form: ExerciseForm) -> PerformedSetValues {
    PerformedSetValues(
      weightKg: WorkoutPlan.availableWeightsKg[0],
      reps: form.repFloor
    )
  }

  private func values(from performedSet: PerformedSet) -> PerformedSetValues {
    PerformedSetValues(weightKg: performedSet.weightKg, reps: performedSet.reps)
  }
}
