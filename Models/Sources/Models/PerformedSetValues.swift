public struct PerformedSetValues: Equatable, Sendable {
  public let weightKg: Int
  public let reps: Int

  public init(weightKg: Int, reps: Int) {
    self.weightKg = weightKg
    self.reps = reps
  }
}
