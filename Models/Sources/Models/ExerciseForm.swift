public enum ExerciseForm: String, CaseIterable, Codable, Identifiable, Sendable {
  case curls = "biceps.curls"
  case hammerCurls = "biceps.hammer-curls"
  case overheadExtensions = "triceps.overhead-extensions"
  case skullCrushers = "triceps.skull-crushers"
  case shoulderPresses = "shoulders.shoulder-presses"
  case lateralRaises = "shoulders.lateral-raises"
}

extension ExerciseForm {
  public var id: String { rawValue }
  
  public var displayName: String {
    switch self {
    case .curls: "Curls"
    case .hammerCurls: "Hammer Curls"
    case .overheadExtensions: "Overhead Extensions"
    case .skullCrushers: "Skull Crushers"
    case .shoulderPresses: "Shoulder Presses"
    case .lateralRaises: "Lateral Raises"
    }
  }
  
  public var muscleGroup: MuscleGroup {
    switch self {
    case .curls, .hammerCurls: .biceps
    case .overheadExtensions, .skullCrushers: .triceps
    case .shoulderPresses, .lateralRaises: .shoulders
    }
  }
  
  public var repRange: ClosedRange<Int> {
    switch self {
    case .curls, .hammerCurls, .shoulderPresses: 6...12
    case .overheadExtensions, .skullCrushers: 8...15
    case .lateralRaises: 6...20
    }
  }
  
  public var repFloor: Int { repRange.lowerBound }
  public var repCeiling: Int { repRange.upperBound }
}
