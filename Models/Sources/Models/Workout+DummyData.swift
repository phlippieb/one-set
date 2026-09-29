extension Workout {
  public static func dummyData() throws -> [Workout] {
    [
      try Workout(
        dayKey: "2026-09-21",
        notes: "Good first day. Everything felt controlled.",
        performedSets: [
          try PerformedSetInput(form: .curls, weightKg: 7, reps: 6),
          try PerformedSetInput(form: .overheadExtensions, weightKg: 7, reps: 8),
          try PerformedSetInput(form: .shoulderPresses, weightKg: 7, reps: 6),
        ]
      ),
      try Workout(
        dayKey: "2026-09-22",
        performedSets: [
          try PerformedSetInput(form: .hammerCurls, weightKg: 7, reps: 6),
          try PerformedSetInput(form: .skullCrushers, weightKg: 7, reps: 8),
          try PerformedSetInput(form: .lateralRaises, weightKg: 7, reps: 10),
        ]
      ),
      try Workout(
        dayKey: "2026-09-23",
        performedSets: [
          try PerformedSetInput(form: .curls, weightKg: 7, reps: 7),
          try PerformedSetInput(form: .overheadExtensions, weightKg: 7, reps: 8),
          try PerformedSetInput(form: .shoulderPresses, weightKg: 7, reps: 6),
        ]
      ),
      try Workout(
        dayKey: "2026-09-24",
        notes: "Skipped triceps because my elbow was sore.",
        performedSets: [
          try PerformedSetInput(form: .hammerCurls, weightKg: 7, reps: 7),
          try PerformedSetInput(form: .lateralRaises, weightKg: 7, reps: 10),
        ]
      ),
      try Workout(
        dayKey: "2026-09-25",
        notes: "Last curl rep was untidy; repeat this next time.",
        performedSets: [
          try PerformedSetInput(
            form: .curls,
            weightKg: 7,
            reps: 8,
            shouldRepeat: true
          ),
          try PerformedSetInput(form: .overheadExtensions, weightKg: 7, reps: 8),
          try PerformedSetInput(form: .shoulderPresses, weightKg: 7, reps: 6),
        ]
      ),
      try Workout(
        dayKey: "2026-09-26",
        performedSets: [
          try PerformedSetInput(form: .hammerCurls, weightKg: 7, reps: 8),
          try PerformedSetInput(form: .skullCrushers, weightKg: 7, reps: 8),
          try PerformedSetInput(form: .lateralRaises, weightKg: 7, reps: 11),
        ]
      ),
      try Workout(
        dayKey: "2026-09-28",
        notes: "Repeated curls with better form. Skipped shoulders for time.",
        performedSets: [
          try PerformedSetInput(form: .curls, weightKg: 7, reps: 8),
          try PerformedSetInput(form: .overheadExtensions, weightKg: 7, reps: 9),
        ]
      ),
    ]
  }
}
