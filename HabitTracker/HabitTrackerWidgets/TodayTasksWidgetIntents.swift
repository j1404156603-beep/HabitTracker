import AppIntents
import Foundation

// Mirror of `zj01/TodayTasksWidgetIntents.swift` — the Xcode target compiles `zj01/`.

@available(iOS 17.0, *)
struct CheckInHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Check In"

    @Parameter(title: "Habit ID")
    var habitID: String

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: habitID) else { return .result() }
        await SharedHabitWidgetStore.checkInToday(habitID: uuid)
        return .result()
    }
}
