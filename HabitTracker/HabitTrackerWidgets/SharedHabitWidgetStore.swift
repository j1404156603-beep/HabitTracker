import Foundation
import WidgetKit

// Mirror of `zj01/SharedHabitWidgetStore.swift` — the Xcode target compiles `zj01/`.

struct WidgetTaskItem: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var isDoneToday: Bool
}

enum SharedHabitWidgetStore {
    @MainActor
    static func todayTasks(max: Int) -> [WidgetTaskItem] {
        let habits = LocalHabitStore().load()
        let cal = Calendar.current
        let now = Date()

        let items = habits.map { h in
            WidgetTaskItem(
                id: h.id,
                title: h.title,
                isDoneToday: h.isCompletedToday(calendar: cal, now: now)
            )
        }

        let pending = items.filter { !$0.isDoneToday }
        let done = items.filter { $0.isDoneToday }
        return Array((pending + done).prefix(max))
    }

    @MainActor
    static func checkInToday(habitID: UUID) async {
        var habits = LocalHabitStore().load()
        guard let idx = habits.firstIndex(where: { $0.id == habitID }) else { return }

        var updated = habits[idx]
        updated.checkInNow(calendar: .current, now: Date())
        habits[idx] = updated
        LocalHabitStore().save(habits)

        WidgetCenter.shared.reloadAllTimelines()
    }
}
