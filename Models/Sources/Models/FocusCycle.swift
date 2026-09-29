public struct FocusCycle: Equatable, Sendable {
  public let focusedGroup: MuscleGroup
  public let startDayKey: String
  public let endDayKey: String
  public let nextFocusedGroup: MuscleGroup
  public let nextStartDayKey: String
}

extension FocusCycle {
  public struct Day: Equatable, Identifiable, Sendable {
    public enum State: Equatable, Sendable {
      case logged
      case missed
      case today(isLogged: Bool)
      case upcoming
    }

    public let dayKey: String
    public let state: State

    public var id: String { dayKey }
  }
}
