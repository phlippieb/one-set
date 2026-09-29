public enum WorkoutPlan {
  public static let availableWeightsKg = [7, 10, 12, 15]
  public static let focusCycleOrder: [MuscleGroup] = [.biceps, .triceps, .shoulders]
  public static let focusCycleDurationDays = 14
  public static let focusCycleEpochDayKey = "2026-09-21"
}

extension WorkoutPlan {
  public static func focusCycle(containing dayKey: String) -> FocusCycle? {
    guard let dayOffset = WorkoutDayKey.days(from: focusCycleEpochDayKey, to: dayKey) else {
      return nil
    }

    let cycleIndex = floorDivision(dayOffset, by: focusCycleDurationDays)
    let groupIndex = positiveModulo(cycleIndex, focusCycleOrder.count)
    let startOffset = cycleIndex * focusCycleDurationDays
    guard let startDayKey = WorkoutDayKey.adding(days: startOffset, to: focusCycleEpochDayKey),
          let endDayKey = WorkoutDayKey.adding(days: focusCycleDurationDays - 1, to: startDayKey),
          let nextStartDayKey = WorkoutDayKey.adding(days: focusCycleDurationDays, to: startDayKey)
            else {
      return nil
    }

    return FocusCycle(
      focusedGroup: focusCycleOrder[groupIndex],
      startDayKey: startDayKey,
      endDayKey: endDayKey,
      nextFocusedGroup: focusCycleOrder[(groupIndex + 1) % focusCycleOrder.count],
      nextStartDayKey: nextStartDayKey
    )
  }

  public static func muscleGroupOrder(on dayKey: String) -> [MuscleGroup]? {
    guard let focusedGroup = focusCycle(containing: dayKey)?.focusedGroup,
          let focusedIndex = focusCycleOrder.firstIndex(of: focusedGroup)
            else {
      return nil
    }

    return focusCycleOrder.indices.map {
      focusCycleOrder[(focusedIndex + $0) % focusCycleOrder.count]
    }
  }
}

private func floorDivision(_ dividend: Int, by divisor: Int) -> Int {
  let quotient = dividend / divisor
  return dividend % divisor < 0 ? quotient - 1 : quotient
}

private func positiveModulo(_ value: Int, _ modulus: Int) -> Int {
  let remainder = value % modulus
  return remainder < 0 ? remainder + modulus : remainder
}
