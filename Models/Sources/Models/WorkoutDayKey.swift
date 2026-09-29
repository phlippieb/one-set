import Foundation

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

  public static func adding(days: Int, to dayKey: String) -> String? {
    guard let components = dateComponents(from: dayKey),
          let calendar = components.calendar,
          let date = calendar.date(from: components),
          let result = calendar.date(byAdding: .day, value: days, to: date)
            else {
      return nil
    }

    return today(now: result, timeZone: calendar.timeZone)
  }

  public static func days(from startDayKey: String, to endDayKey: String) -> Int? {
    guard let startComponents = dateComponents(from: startDayKey),
          let endComponents = dateComponents(from: endDayKey),
          let calendar = startComponents.calendar,
          let start = calendar.date(from: startComponents),
          let end = calendar.date(from: endComponents)
            else {
      return nil
    }

    return calendar.dateComponents([.day], from: start, to: end).day
  }
}
