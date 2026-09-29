public enum MuscleGroup: String, CaseIterable, Codable, Sendable {
  case biceps
  case triceps
  case shoulders
}

extension MuscleGroup {
  public var displayName: String {
    switch self {
    case .biceps: "Biceps"
    case .triceps: "Triceps"
    case .shoulders: "Shoulders"
    }
  }
  
  public var forms: [ExerciseForm] {
    switch self {
    case .biceps: [.curls, .hammerCurls]
    case .triceps: [.overheadExtensions, .skullCrushers]
    case .shoulders: [.shoulderPresses, .lateralRaises]
    }
  }
}
