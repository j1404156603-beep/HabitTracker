import Foundation

@MainActor
final class LocalHabitStore {
    private let fileURL: URL

    init(filename: String = "habits.json") {
        let fm = FileManager.default
        let base: URL
        if let groupContainer = fm.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.id) {
            base = groupContainer
        } else {
            base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        }

        let dir = base.appendingPathComponent("HabitTracker", isDirectory: true)
        self.fileURL = dir.appendingPathComponent(filename)
    }

    func load() -> [Habit] {
        do {
            let dir = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

            guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([Habit].self, from: data)
        } catch {
            return []
        }
    }

    func save(_ habits: [Habit]) {
        do {
            let dir = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(habits)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // best-effort local persistence
        }
    }
}
