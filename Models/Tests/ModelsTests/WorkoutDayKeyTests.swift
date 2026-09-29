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
