import CloudKit
import Combine
import Foundation

@MainActor
final class CloudKitHabitStore: ObservableObject {
    @Published private(set) var habits: [Habit] = []
    @Published private(set) var isSyncing: Bool = false
    @Published var lastErrorMessage: String?
    var locale: Locale = .current

    private let container: CKContainer
    private let db: CKDatabase
    private let recordType = "Habit"

    init(container: CKContainer = .default()) {
        self.container = container
        self.db = container.privateCloudDatabase
    }

    func refreshFromCloud() async {
        lastErrorMessage = nil

        isSyncing = true
        defer { isSyncing = false }

        do {
            let status = try await accountStatus()
            guard status == .available else {
                lastErrorMessage = String(localized: "cloudkit_icloud_unavailable", locale: locale)
                return
            }

            let records = try await queryAllHabits()
            let decoded = records.compactMap { Self.habit(from: $0) }
                .sorted(by: { $0.createdAt < $1.createdAt })
            habits = decoded
        } catch {
            let format = String(localized: "cloudkit_sync_failed", locale: locale)
            lastErrorMessage = String(format: format, error.localizedDescription)
        }
    }

    func upsert(_ habit: Habit) async {
        lastErrorMessage = nil
        do {
            let record = Self.record(from: habit, recordType: recordType)
            _ = try await save(record)

            if let idx = habits.firstIndex(where: { $0.id == habit.id }) {
                habits[idx] = habit
            } else {
                habits.append(habit)
                habits.sort(by: { $0.createdAt < $1.createdAt })
            }
        } catch {
            let format = String(localized: "cloudkit_save_failed", locale: locale)
            lastErrorMessage = String(format: format, error.localizedDescription)
        }
    }

    func delete(_ habit: Habit) async {
        lastErrorMessage = nil
        do {
            _ = try await deleteRecordID(CKRecord.ID(recordName: habit.id.uuidString))
            habits.removeAll(where: { $0.id == habit.id })
        } catch {
            let format = String(localized: "cloudkit_delete_failed", locale: locale)
            lastErrorMessage = String(format: format, error.localizedDescription)
        }
    }

    // MARK: - CloudKit wrappers

    private func accountStatus() async throws -> CKAccountStatus {
        try await withCheckedThrowingContinuation { continuation in
            container.accountStatus { status, error in
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: status)
            }
        }
    }

    private func queryAllHabits() async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let result = try await db.records(matching: query)
        var records: [CKRecord] = []
        records.reserveCapacity(result.matchResults.count)
        for (_, match) in result.matchResults {
            if case .success(let record) = match {
                records.append(record)
            }
        }
        return records
    }

    private func save(_ record: CKRecord) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            db.save(record) { saved, error in
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: saved ?? record)
            }
        }
    }

    private func deleteRecordID(_ id: CKRecord.ID) async throws -> CKRecord.ID {
        try await withCheckedThrowingContinuation { continuation in
            db.delete(withRecordID: id) { deleted, error in
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: deleted ?? id)
            }
        }
    }

    // MARK: - Mapping

    private static func record(from habit: Habit, recordType: String) -> CKRecord {
        let id = CKRecord.ID(recordName: habit.id.uuidString)
        let record = CKRecord(recordType: recordType, recordID: id)
        record["id"] = habit.id.uuidString as CKRecordValue
        record["title"] = habit.title as CKRecordValue
        record["period"] = encodePeriod(habit.period) as CKRecordValue
        if let w = habit.dailyTimeWindow {
            record["dailyStartMinutes"] = w.startMinutes as CKRecordValue
            record["dailyEndMinutes"] = w.endMinutes as CKRecordValue
        }
        record["createdAt"] = habit.createdAt as CKRecordValue
        record["updatedAt"] = habit.updatedAt as CKRecordValue
        record["completions"] = habit.completions.map { $0 as NSDate } as CKRecordValue
        return record
    }

    private static func habit(from record: CKRecord) -> Habit? {
        guard
            let idStr = record["id"] as? String,
            let id = UUID(uuidString: idStr),
            let title = record["title"] as? String,
            let periodStr = record["period"] as? String,
            let period = decodePeriod(periodStr),
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else { return nil }

        let completions = (record["completions"] as? [NSDate])?.map { $0 as Date } ?? []
        let start = record["dailyStartMinutes"] as? Int
        let end = record["dailyEndMinutes"] as? Int
        let window: DailyTimeWindow?
        if let start, let end, end > start {
            window = DailyTimeWindow(startMinutes: start, endMinutes: end)
        } else {
            window = nil
        }
        return Habit(id: id, title: title, period: period, dailyTimeWindow: window, createdAt: createdAt, updatedAt: updatedAt, completions: completions)
    }

    private static func encodePeriod(_ period: HabitPeriod) -> String {
        switch period {
        case .daily:
            return "daily"
        case .weekly(let times):
            return "weekly:\(times)"
        case .monthly(let days):
            return "monthly:\(days)"
        }
    }

    private static func decodePeriod(_ raw: String) -> HabitPeriod? {
        if raw == "daily" { return .daily }
        if raw.hasPrefix("weekly:") {
            guard let n = Int(raw.dropFirst("weekly:".count)), (1...7).contains(n) else { return nil }
            return .weekly(timesPerWeek: n)
        }
        if raw.hasPrefix("monthly:") {
            guard let n = Int(raw.dropFirst("monthly:".count)), (1...31).contains(n) else { return nil }
            return .monthly(daysPerMonth: n)
        }
        return nil
    }
}

