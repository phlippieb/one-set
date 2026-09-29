import Foundation
import SwiftData

public enum MuscleGroup: String, CaseIterable, Codable, Sendable {
    case biceps
    case triceps
    case shoulders

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

public enum ExerciseForm: String, CaseIterable, Codable, Identifiable, Sendable {
    case curls = "biceps.curls"
    case hammerCurls = "biceps.hammer-curls"
    case overheadExtensions = "triceps.overhead-extensions"
    case skullCrushers = "triceps.skull-crushers"
    case shoulderPresses = "shoulders.shoulder-presses"
    case lateralRaises = "shoulders.lateral-raises"

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

public enum WorkoutPlan {
    public static let availableWeightsKg = [7, 10, 12, 15]
}

public enum WorkoutDayKey {
    public static func today(
        now: Date = .now,
        timeZone: TimeZone = .current
    ) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: now)

        return String(
            format: "%04d-%02d-%02d",
            components.year!,
            components.month!,
            components.day!
        )
    }

    public static func dateComponents(from dayKey: String) -> DateComponents? {
        let bytes = Array(dayKey.utf8)
        guard bytes.count == 10,
              bytes[4] == Character("-").asciiValue,
              bytes[7] == Character("-").asciiValue,
              bytes.enumerated().allSatisfy({ index, byte in
                  index == 4 || index == 7 || (Character("0").asciiValue!...Character("9").asciiValue!).contains(byte)
              })
        else {
            return nil
        }

        let year = Int(dayKey.prefix(4))!
        let month = Int(dayKey.dropFirst(5).prefix(2))!
        let day = Int(dayKey.suffix(2))!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day

        guard year > 0,
              let date = calendar.date(from: components),
              calendar.component(.year, from: date) == year,
              calendar.component(.month, from: date) == month,
              calendar.component(.day, from: date) == day
        else {
            return nil
        }

        return components
    }

    public static func isValid(_ dayKey: String) -> Bool {
        dateComponents(from: dayKey) != nil
    }
}

public enum ModelValidationError: Error, Equatable, Sendable {
    case workoutRequiresPerformedSet
    case tooManyPerformedSets
    case duplicateMuscleGroup(MuscleGroup)
    case invalidWeightKg(Int)
    case invalidReps(Int)
}

public struct PerformedSetInput: Equatable, Sendable {
    public let form: ExerciseForm
    public let weightKg: Int
    public let reps: Int
    public let shouldRepeat: Bool

    public init(
        form: ExerciseForm,
        weightKg: Int,
        reps: Int,
        shouldRepeat: Bool = false
    ) throws {
        guard WorkoutPlan.availableWeightsKg.contains(weightKg) else {
            throw ModelValidationError.invalidWeightKg(weightKg)
        }
        guard reps >= 1 else {
            throw ModelValidationError.invalidReps(reps)
        }

        self.form = form
        self.weightKg = weightKg
        self.reps = reps
        self.shouldRepeat = shouldRepeat
    }
}

@Model
public final class Workout {
    @Attribute(.unique) public private(set) var dayKey: String
    public var notes: String
    @Relationship(deleteRule: .cascade, inverse: \PerformedSet.workout)
    public private(set) var performedSets: [PerformedSet]

    public init(
        notes: String = "",
        performedSets: [PerformedSetInput],
        now: Date = .now,
        timeZone: TimeZone = .current
    ) throws {
        guard !performedSets.isEmpty else {
            throw ModelValidationError.workoutRequiresPerformedSet
        }
        guard performedSets.count <= MuscleGroup.allCases.count else {
            throw ModelValidationError.tooManyPerformedSets
        }

        var muscleGroups = Set<MuscleGroup>()
        for input in performedSets where !muscleGroups.insert(input.form.muscleGroup).inserted {
            throw ModelValidationError.duplicateMuscleGroup(input.form.muscleGroup)
        }

        self.dayKey = WorkoutDayKey.today(now: now, timeZone: timeZone)
        self.notes = notes
        self.performedSets = []
        self.performedSets = performedSets.map { PerformedSet(workout: self, input: $0) }
    }
}

@Model
public final class PerformedSet {
    public private(set) var formID: String
    public private(set) var weightKg: Int
    public private(set) var reps: Int
    public var shouldRepeat: Bool
    public private(set) var workout: Workout

    public var form: ExerciseForm {
        // All writes pass through typed, validated APIs.
        ExerciseForm(rawValue: formID)!
    }

    init(workout: Workout, input: PerformedSetInput) {
        self.workout = workout
        self.formID = input.form.id
        self.weightKg = input.weightKg
        self.reps = input.reps
        self.shouldRepeat = input.shouldRepeat
    }

    public func update(with input: PerformedSetInput) throws {
        if input.form.muscleGroup != form.muscleGroup,
           workout.performedSets.contains(where: {
               $0 !== self && $0.form.muscleGroup == input.form.muscleGroup
           }) {
            throw ModelValidationError.duplicateMuscleGroup(input.form.muscleGroup)
        }

        formID = input.form.id
        weightKg = input.weightKg
        reps = input.reps
        shouldRepeat = input.shouldRepeat
    }
}
