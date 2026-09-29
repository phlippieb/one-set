import Foundation
import Models

enum WorkoutDateDisplay {
  static func relative(_ dayKey: String, to referenceDate: Date = .now) -> String {
    let calendar = displayCalendar()
    guard let date = date(from: dayKey, calendar: calendar) else {
      return dayKey
    }

    if calendar.isDate(date, inSameDayAs: referenceDate) {
      return "Today"
    }
    if let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDate),
      calendar.isDate(date, inSameDayAs: yesterday)
    {
      return "Yesterday"
    }

    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = .current
    formatter.timeZone = calendar.timeZone
    if calendar.isDate(date, equalTo: referenceDate, toGranularity: .weekOfYear) {
      formatter.dateFormat = "EEEE"
      return formatter.string(from: date)
    }
    if let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: referenceDate),
      calendar.isDate(date, equalTo: previousWeek, toGranularity: .weekOfYear)
    {
      formatter.dateFormat = "EEEE"
      return "Last \(formatter.string(from: date))"
    }

    let isSameYear = calendar.component(.year, from: date)
      == calendar.component(.year, from: referenceDate)
    formatter.dateFormat = isSameYear ? "EEEE d MMM" : "EEEE d MMM yyyy"
    return formatter.string(from: date)
  }

  static func range(from startDayKey: String, to endDayKey: String) -> String? {
    let calendar = displayCalendar()
    guard let startDay = date(from: startDayKey, calendar: calendar),
      let endDay = date(from: endDayKey, calendar: calendar)
    else {
      return nil
    }

    let formatter = DateIntervalFormatter()
    formatter.calendar = calendar
    formatter.locale = .current
    formatter.timeZone = calendar.timeZone
    formatter.dateTemplate = "dMMM"
    return formatter.string(from: startDay, to: endDay)
  }

  private static func date(from dayKey: String, calendar: Calendar) -> Date? {
    guard let components = WorkoutDayKey.dateComponents(from: dayKey) else {
      return nil
    }
    var localComponents = components
    localComponents.calendar = calendar
    localComponents.timeZone = calendar.timeZone
    return calendar.date(from: localComponents)
  }

  private static func displayCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = .current
    calendar.timeZone = .current
    return calendar
  }
}
