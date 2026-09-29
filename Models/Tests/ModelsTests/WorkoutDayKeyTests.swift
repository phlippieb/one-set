import Foundation
import Testing

@testable import Models

@Test("Day keys use the Gregorian local calendar")
func dayKeys() {
    let epoch = Date(timeIntervalSince1970: 0)

    #expect(WorkoutDayKey.today(now: epoch, timeZone: TimeZone(secondsFromGMT: 0)!) == "1970-01-01")
    #expect(WorkoutDayKey.today(now: epoch, timeZone: TimeZone(secondsFromGMT: -8 * 60 * 60)!) == "1969-12-31")
    #expect(WorkoutDayKey.isValid("2024-02-29"))
    #expect(!WorkoutDayKey.isValid("2023-02-29"))
    #expect(!WorkoutDayKey.isValid("2026-9-21"))
}

@Test("Day-key arithmetic uses civil Gregorian days")
func dayKeyArithmetic() {
    #expect(WorkoutDayKey.adding(days: 1, to: "2024-02-28") == "2024-02-29")
    #expect(WorkoutDayKey.adding(days: -1, to: "2027-01-01") == "2026-12-31")
    #expect(WorkoutDayKey.days(from: "2024-02-28", to: "2024-03-01") == 2)
    #expect(WorkoutDayKey.days(from: "2024-03-01", to: "2024-02-28") == -2)
    #expect(WorkoutDayKey.adding(days: 1, to: "2026-9-21") == nil)
    #expect(WorkoutDayKey.days(from: "invalid", to: "2026-09-21") == nil)
}
