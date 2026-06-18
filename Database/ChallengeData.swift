import Foundation
import SwiftUI

// A typed notification name for when challenge completion changes
extension Notification.Name {
    static let challengeUpdated = Notification.Name("ChallengeUpdated")
}

class ChallengeData {
    static let shared = ChallengeData()
    
    private var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd"
        return "challenge_\(formatter.string(from: Date()))"
    }
    
    func isCompleted() -> Bool {
        return UserDefaults.standard.bool(forKey: todayKey)
    }
    
    func markAsCompleted() {
        // Mark today's daily challenge as completed (legacy key for quick lookup)
        UserDefaults.standard.set(true, forKey: todayKey)

        // Persist into the calendar log keyed by yyyy-MM-dd for calendar views
        let calendarKey = dateKeyForCalendar(Date())
        var currentLog = getCalendarLog()
        currentLog[calendarKey] = true
        saveCalendarLog(currentLog)

        // Notify observers that the challenge state changed
        NotificationCenter.default.post(name: .challengeUpdated, object: nil)
    }
    
    /// Returns whether the challenge is completed on the given date (defaults to today)
    func isCompleted(on date: Date = Date()) -> Bool {
        let key = dateKeyForCalendar(date)
        let log = getCalendarLog()
        if let value = log[key] {
            return value
        }
        // Fallback to legacy per-day key for today only
        if Calendar.current.isDateInToday(date) {
            return isCompleted()
        }
        return false
    }
    
    /// Mark the challenge as completed for an arbitrary date (used when backfilling or syncing)
    func markAsCompleted(on date: Date) {
        // If it's today, also set the quick lookup key
        if Calendar.current.isDateInToday(date) {
            UserDefaults.standard.set(true, forKey: todayKey)
        }
        var log = getCalendarLog()
        log[dateKeyForCalendar(date)] = true
        saveCalendarLog(log)
        NotificationCenter.default.post(name: .challengeUpdated, object: nil)
    }
    
    /// Retrieve the entire completion log keyed by yyyy-MM-dd for calendar rendering
    func completionLog() -> [String: Bool] {
        return getCalendarLog()
    }
    
    private func dateKeyForCalendar(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }
    
    /// Internal storage for the calendar log in UserDefaults as a JSON string
    private func getCalendarLog() -> [String: Bool] {
        let json = UserDefaults.standard.string(forKey: "challenge.completionLog") ?? "{}"
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Bool] else { return [:] }
        return dict
    }
    
    /// Persists the calendar log to UserDefaults
    private func saveCalendarLog(_ dict: [String: Bool]) {
        if let data = try? JSONSerialization.data(withJSONObject: dict),
           let str = String(data: data, encoding: .utf8) {
            UserDefaults.standard.set(str, forKey: "challenge.completionLog")
        }
    }
}

