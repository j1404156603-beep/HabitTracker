import Combine
import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class AppSettings: ObservableObject {
    private static let sharedStore = UserDefaults(suiteName: AppGroup.id)

    @AppStorage("settings.notificationsEnabled", store: sharedStore) var notificationsEnabled: Bool = true
    @AppStorage("settings.syncEnabled") var syncEnabled: Bool = true
    @AppStorage("settings.reminderMode", store: sharedStore) var reminderModeRawValue: String = ReminderMode.interval.rawValue
    @AppStorage("settings.reminderIntervalMinutes", store: sharedStore) var reminderIntervalMinutes: Int = 60
    @AppStorage("settings.reminderStartMinutes", store: sharedStore) var reminderStartMinutes: Int = 8 * 60
    @AppStorage("settings.reminderEndMinutes", store: sharedStore) var reminderEndMinutes: Int = 22 * 60
    @AppStorage("settings.reminderQuietStartMinutes", store: sharedStore) var reminderQuietStartMinutes: Int = 22 * 60
    @AppStorage("settings.reminderQuietEndMinutes", store: sharedStore) var reminderQuietEndMinutes: Int = 8 * 60
    @AppStorage("settings.reminderBannerEnabled", store: sharedStore) var reminderBannerEnabled: Bool = true
    @AppStorage("settings.reminderSoundEnabled", store: sharedStore) var reminderSoundEnabled: Bool = true
    @AppStorage("settings.reminderHapticsEnabled", store: sharedStore) var reminderHapticsEnabled: Bool = true
    @AppStorage("settings.dailyWaterGoalML", store: sharedStore) var dailyWaterGoalML: Int = 1000
    @AppStorage("settings.singleCheckInML", store: sharedStore) var singleCheckInML: Int = 200

    enum ReminderMode: String, CaseIterable, Identifiable {
        case interval
        case customWindow

        var id: String { rawValue }

        var labelKey: LocalizedStringKey {
            switch self {
            case .interval: return "settings_reminder_mode_interval"
            case .customWindow: return "settings_reminder_mode_window"
            }
        }
    }

    var reminderMode: ReminderMode {
        get { ReminderMode(rawValue: reminderModeRawValue) ?? .interval }
        set { reminderModeRawValue = newValue.rawValue }
    }

    enum Appearance: String, CaseIterable, Identifiable {
        case system
        case dark
        case light

        var id: String { rawValue }

        var labelKey: LocalizedStringKey {
            switch self {
            case .system: return "appearance_system"
            case .dark: return "appearance_dark"
            case .light: return "appearance_light"
            }
        }

        var preferredColorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .dark: return .dark
            case .light: return .light
            }
        }
    }

    @AppStorage("settings.appearance") var appearanceRawValue: String = Appearance.system.rawValue

    var appearance: Appearance {
        get { Appearance(rawValue: appearanceRawValue) ?? .system }
        set { appearanceRawValue = newValue.rawValue }
    }

    enum AppLanguage: String, CaseIterable, Identifiable {
        case zhHans = "zh-Hans"
        case en = "en"

        var id: String { rawValue }

        var displayNameKey: LocalizedStringKey {
            switch self {
            case .zhHans: return "settings_language_zh"
            case .en: return "settings_language_en"
            }
        }

        var locale: Locale {
            Locale(identifier: rawValue)
        }
    }

    @AppStorage("settings.language") var languageRawValue: String = AppLanguage.zhHans.rawValue

    var language: AppLanguage {
        get { AppLanguage(rawValue: languageRawValue) ?? .zhHans }
        set { languageRawValue = newValue.rawValue }
    }

    func reminderSummaryBody(doneCount: Int) -> String {
        let drankML = max(0, doneCount) * max(50, singleCheckInML)
        let remainML = max(0, dailyWaterGoalML - drankML)
        return String(localized: "reminder_body \(drankML) \(remainML)")
    }

    func requestNotificationPermissionIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted ?? false
    }

    func scheduleReminders(using habits: [Habit]) async {
        guard notificationsEnabled else {
            await ReminderScheduler.cancelAll()
            return
        }
        let granted = await requestNotificationPermissionIfNeeded()
        guard granted else { return }
        await ReminderScheduler.schedule(settings: self, habits: habits)
    }
}

enum ReminderScheduler {
    private static let idPrefix = "habittracker.reminder."
    private static let calendar = Calendar.current

    static func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    static func schedule(settings: AppSettings, habits: [Habit]) async {
        await cancelAll()

        let doneCount = habits.filter { $0.isCompletedToday() }.count
        let content = buildContent(settings: settings, doneCount: doneCount)

        switch settings.reminderMode {
        case .interval:
            await scheduleIntervalReminders(content: content, settings: settings)
        case .customWindow:
            await scheduleWindowReminders(content: content, settings: settings)
        }
    }

    private static func buildContent(settings: AppSettings, doneCount: Int) -> UNMutableNotificationContent {
        let c = UNMutableNotificationContent()
        c.title = String(localized: "reminder_title")
        c.body = settings.reminderSummaryBody(doneCount: doneCount)
        c.interruptionLevel = settings.reminderBannerEnabled ? .active : .passive
        if settings.reminderSoundEnabled {
            c.sound = .default
        }
        return c
    }

    private static func scheduleIntervalReminders(content: UNMutableNotificationContent, settings: AppSettings) async {
        let every = max(30, settings.reminderIntervalMinutes)
        let start = clamp(settings.reminderStartMinutes)
        let end = clamp(settings.reminderEndMinutes)

        for minute in stride(from: start, through: end, by: every) {
            guard isNotInQuietHours(minute: minute, settings: settings) else { continue }
            var dc = DateComponents()
            dc.hour = minute / 60
            dc.minute = minute % 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            let req = UNNotificationRequest(
                identifier: "\(idPrefix)interval.\(minute)",
                content: content,
                trigger: trigger
            )
            try? await UNUserNotificationCenter.current().add(req)
        }
    }

    private static func scheduleWindowReminders(content: UNMutableNotificationContent, settings: AppSettings) async {
        let start = clamp(settings.reminderStartMinutes)
        let end = clamp(settings.reminderEndMinutes)
        guard end > start else { return }

        // 以 2 小时为步长在自定义时段内提醒，避免过于打扰。
        for minute in stride(from: start, through: end, by: 120) {
            guard isNotInQuietHours(minute: minute, settings: settings) else { continue }
            var dc = DateComponents()
            dc.hour = minute / 60
            dc.minute = minute % 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            let req = UNNotificationRequest(
                identifier: "\(idPrefix)window.\(minute)",
                content: content,
                trigger: trigger
            )
            try? await UNUserNotificationCenter.current().add(req)
        }
    }

    private static func isNotInQuietHours(minute: Int, settings: AppSettings) -> Bool {
        let qStart = clamp(settings.reminderQuietStartMinutes)
        let qEnd = clamp(settings.reminderQuietEndMinutes)
        if qStart == qEnd { return true }
        if qStart < qEnd {
            return !(minute >= qStart && minute < qEnd)
        }
        // 跨天 quiet hours，例如 22:00 -> 08:00
        return !(minute >= qStart || minute < qEnd)
    }

    private static func clamp(_ minute: Int) -> Int {
        max(0, min(23 * 60 + 59, minute))
    }
}

