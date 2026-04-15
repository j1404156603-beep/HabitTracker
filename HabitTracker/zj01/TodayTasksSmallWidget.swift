import SwiftUI
import WidgetKit

// Mirror of `zj01/TodayTasksSmallWidget.swift` — the Xcode target compiles `zj01/`.

struct TodayTasksSmallEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTaskItem]
}

struct TodayTasksSmallProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayTasksSmallEntry {
        TodayTasksSmallEntry(date: Date(), tasks: sampleTasksSmall)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayTasksSmallEntry) -> Void) {
        Task { @MainActor in
            let entry = TodayTasksSmallEntry(date: Date(), tasks: SharedHabitWidgetStore.todayTasks(max: 5))
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayTasksSmallEntry>) -> Void) {
        Task { @MainActor in
            let entry = TodayTasksSmallEntry(date: Date(), tasks: SharedHabitWidgetStore.todayTasks(max: 5))
            let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private var sampleTasksSmall: [WidgetTaskItem] {
        [
            .init(id: UUID(), title: "Drink water", isDoneToday: false),
            .init(id: UUID(), title: "Eat meal", isDoneToday: true),
        ]
    }
}

struct TodayTasksSmallEntryView: View {
    let entry: TodayTasksSmallEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("home_title")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            if entry.tasks.isEmpty {
                Text("home_empty_title")
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.tasks) { t in
                        HStack(alignment: .center, spacing: 8) {
                            Capsule()
                                .fill(t.isDoneToday ? Color.theme.secondaryText.opacity(0.35) : Color.theme.accent.opacity(0.55))
                                .frame(width: 3, height: 14)

                            Text(t.title)
                                .font(.system(size: 13, weight: t.isDoneToday ? .regular : .semibold))
                                .foregroundStyle(t.isDoneToday ? Color.theme.secondaryText : Color.theme.accent)
                                .strikethrough(t.isDoneToday, pattern: .solid, color: Color.theme.secondaryText)
                                .lineLimit(2)
                                .minimumScaleFactor(0.72)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.theme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.theme.divider.opacity(0.65), lineWidth: 1)
                        )
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .widgetURL(URL(string: "habittracker://")!)
        .containerBackground(Color.theme.background, for: .widget)
    }
}

struct TodayTasksSmallWidget: Widget {
    let kind = "TodayTasksSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayTasksSmallProvider()) { entry in
            TodayTasksSmallEntryView(entry: entry)
        }
        .configurationDisplayName(Text("home_title"))
        .description(Text("widget_desc_today_compact"))
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    TodayTasksSmallWidget()
} timeline: {
    TodayTasksSmallEntry(date: .now, tasks: [
        .init(id: UUID(), title: "Drink water", isDoneToday: false),
        .init(id: UUID(), title: "Eat meal", isDoneToday: true),
    ])
}
