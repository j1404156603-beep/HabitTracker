import Combine
import Foundation
import WidgetKit

@MainActor
final class HabitStore: ObservableObject {
    @Published private(set) var habits: [Habit] = []
    @Published private(set) var isSyncing: Bool = false
    @Published var lastErrorMessage: String?

    private let local = LocalHabitStore()
    private let cloud = CloudKitHabitStore()
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
        self.habits = local.load().sorted(by: { $0.createdAt < $1.createdAt })

        // Keep CloudKit error messages aligned with in-app language switching.
        cloud.locale = settings.language.locale
    }

    private func syncCloudLocaleFromSettings() {
        cloud.locale = settings.language.locale
    }

    func reloadLocal() {
        habits = local.load().sorted(by: { $0.createdAt < $1.createdAt })
    }

    /// Used by widget deep links; mirrors LocalHabitStore + optional cloud upsert.
    func checkInHabitFromWidget(id: UUID) async {
        lastErrorMessage = nil
        reloadLocal()
        guard var habit = habits.first(where: { $0.id == id }) else { return }
        guard !habit.isCompletedToday() else { return }
        habit.checkInNow()
        await upsert(habit)
    }

    func refresh() async {
        lastErrorMessage = nil
        reloadLocal()

        guard settings.syncEnabled else { return }
        syncCloudLocaleFromSettings()
        await refreshFromCloudAndMerge()
    }

    func upsert(_ habit: Habit) async {
        lastErrorMessage = nil

        upsertLocal(habit)

        guard settings.syncEnabled else { return }
        syncCloudLocaleFromSettings()
        await cloud.upsert(habit)
        if let err = cloud.lastErrorMessage { lastErrorMessage = err }
    }

    func delete(_ habit: Habit) async {
        lastErrorMessage = nil

        deleteLocal(habit)

        guard settings.syncEnabled else { return }
        syncCloudLocaleFromSettings()
        await cloud.delete(habit)
        if let err = cloud.lastErrorMessage { lastErrorMessage = err }
    }

    func deleteAllHabits() async {
        lastErrorMessage = nil
        syncCloudLocaleFromSettings()

        // Snapshot to avoid mutating while iterating.
        let all = habits
        for h in all {
            await delete(h)
        }
    }

    // MARK: - Local mutations

    private func upsertLocal(_ habit: Habit) {
        if let idx = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[idx] = habit
        } else {
            habits.append(habit)
        }
        habits.sort(by: { $0.createdAt < $1.createdAt })
        local.save(habits)
        WidgetCenter.shared.reloadAllTimelines()
        Task { await settings.scheduleReminders(using: habits) }
    }

    private func deleteLocal(_ habit: Habit) {
        habits.removeAll(where: { $0.id == habit.id })
        local.save(habits)
        WidgetCenter.shared.reloadAllTimelines()
        Task { await settings.scheduleReminders(using: habits) }
    }

    // MARK: - Cloud merge

    private func refreshFromCloudAndMerge() async {
        isSyncing = true
        defer { isSyncing = false }

        syncCloudLocaleFromSettings()
        await cloud.refreshFromCloud()
        if let err = cloud.lastErrorMessage {
            lastErrorMessage = err
            return
        }

        let merged = merge(local: habits, cloud: cloud.habits)
        habits = merged.sorted(by: { $0.createdAt < $1.createdAt })
        local.save(habits)
        WidgetCenter.shared.reloadAllTimelines()
        Task { await settings.scheduleReminders(using: habits) }

        // Best-effort push local-only items to cloud
        for h in habits {
            syncCloudLocaleFromSettings()
            await cloud.upsert(h)
        }
    }

    private func merge(local: [Habit], cloud: [Habit]) -> [Habit] {
        var byID: [UUID: Habit] = [:]
        for h in local { byID[h.id] = h }
        for h in cloud {
            if let existing = byID[h.id] {
                byID[h.id] = (h.updatedAt >= existing.updatedAt) ? h : existing
            } else {
                byID[h.id] = h
            }
        }
        return Array(byID.values)
    }
}

