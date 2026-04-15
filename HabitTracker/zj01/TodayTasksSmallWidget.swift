import SwiftUI
import WidgetKit

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
            let entry = TodayTasksSmallEntry(date: Date(), tasks: SharedHabitWidgetStore.todayTasks(max: 4))
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayTasksSmallEntry>) -> Void) {
        Task { @MainActor in
            let entry = TodayTasksSmallEntry(date: Date(), tasks: SharedHabitWidgetStore.todayTasks(max: 4))
            let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private var sampleTasksSmall: [WidgetTaskItem] {
        [
            .init(id: UUID(), title: "阅读", icon: "book", isDoneToday: false),
            .init(id: UUID(), title: "喝水", icon: "drop", isDoneToday: true),
            .init(id: UUID(), title: "运动", icon: "figure.walk", isDoneToday: false),
        ]
    }
}

struct TodayTasksSmallEntryView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: TodayTasksSmallEntry

    private var widgetBackground: Color {
        colorScheme == .dark ? Color(light: 0x1A1A1A, dark: 0x1A1A1A) : Color(light: 0xF2F2F7, dark: 0x1A1A1A)
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color(light: 0x1A1A1A, dark: 0x1A1A1A) : Color(light: 0xFFFFFF, dark: 0x1A1A1A)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if entry.tasks.isEmpty {
                Text("home_empty_title")
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(entry.tasks.prefix(4))) { t in
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: t.icon)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(t.isDoneToday ? Color.theme.secondaryText : Color.theme.accent)
                                .frame(width: 14)

                            Text(t.title)
                                .font(.system(size: 13, weight: t.isDoneToday ? .regular : .semibold))
                                .foregroundStyle(t.isDoneToday ? Color.theme.secondaryText : Color.theme.accent)
                                .strikethrough(t.isDoneToday, pattern: .solid, color: Color.theme.secondaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.theme.divider.opacity(0.6), lineWidth: 1)
                        )
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .widgetURL(URL(string: "habittracker://")!)
        .containerBackground(widgetBackground, for: .widget)
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
        .init(id: UUID(), title: "阅读", icon: "book", isDoneToday: false),
        .init(id: UUID(), title: "喝水", icon: "drop", isDoneToday: true),
        .init(id: UUID(), title: "运动", icon: "figure.walk", isDoneToday: false),
        .init(id: UUID(), title: "冥想", icon: "brain.head.profile", isDoneToday: false),
        .init(id: UUID(), title: "记账", icon: "pencil", isDoneToday: true),
    ])
}
