import Foundation

enum HabitPeriod: Codable, Equatable, Hashable {
    case daily
    case weekly(timesPerWeek: Int)
    case monthly(daysPerMonth: Int)

    var displayTitle: String {
        switch self {
        case .daily:
            return String(localized: "create_habit_cycle_daily")
        case .weekly(let times):
            return String(localized: "create_habit_weekly_stepper \(times)")
        case .monthly(let days):
            return String(localized: "create_habit_monthly_stepper \(days)")
        }
    }
}

struct DailyTimeWindow: Codable, Equatable, Hashable {
    /// Minutes since midnight, range 0...1439
    var startMinutes: Int
    /// Minutes since midnight, range 0...1439
    var endMinutes: Int

    init(startMinutes: Int, endMinutes: Int) {
        self.startMinutes = max(0, min(1439, startMinutes))
        self.endMinutes = max(0, min(1439, endMinutes))
    }

    func displayText() -> String {
        "\(format(startMinutes))-\(format(endMinutes))"
    }

    private func format(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return String(format: "%02d:%02d", h, m)
    }
}

struct Habit: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var period: HabitPeriod
    var dailyTimeWindow: DailyTimeWindow?
    var createdAt: Date
    var updatedAt: Date
    var completions: [Date]

    init(
        id: UUID = UUID(),
        title: String,
        period: HabitPeriod = .daily,
        dailyTimeWindow: DailyTimeWindow? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completions: [Date] = []
    ) {
        self.id = id
        self.title = title
        self.period = period
        self.dailyTimeWindow = dailyTimeWindow
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completions = completions
    }

    var periodDisplayText: String {
        switch period {
        case .daily:
            if let w = dailyTimeWindow {
                return "\(String(localized: "create_habit_cycle_daily")) \(w.displayText())"
            }
            return String(localized: "create_habit_cycle_daily")
        case .weekly, .monthly:
            return period.displayTitle
        }
    }

    mutating func checkInNow(calendar: Calendar = .current, now: Date = Date()) {
        guard !isCompletedToday(calendar: calendar, now: now) else { return }
        completions.append(now)
        updatedAt = now
    }

    func isCompletedToday(calendar: Calendar = .current, now: Date = Date()) -> Bool {
        completions.contains(where: { calendar.isDate($0, inSameDayAs: now) })
    }
}
