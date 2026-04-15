import AppIntents
import SwiftUI
import WidgetKit

// Mirror of `zj01/TodayTasksMediumWidget.swift` — the Xcode target compiles `zj01/`.

struct TodayTasksMediumEntry: TimelineEntry {
    let date: Date
    let family: WidgetFamily
    let tasks: [WidgetTaskItem]
}

struct TodayTasksMediumProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayTasksMediumEntry {
        TodayTasksMediumEntry(date: Date(), family: context.family, tasks: sampleTasksMedium)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayTasksMediumEntry) -> Void) {
        let family = context.family
        let max = maxTasks(for: family)
        Task { @MainActor in
            let entry = TodayTasksMediumEntry(
                date: Date(),
                family: family,
                tasks: SharedHabitWidgetStore.todayTasks(max: max)
            )
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayTasksMediumEntry>) -> Void) {
        let family = context.family
        let max = maxTasks(for: family)
        Task { @MainActor in
            let entry = TodayTasksMediumEntry(
                date: Date(),
                family: family,
                tasks: SharedHabitWidgetStore.todayTasks(max: max)
            )
            let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func maxTasks(for family: WidgetFamily) -> Int {
        switch family {
        case .systemMedium:
            return 4
        case .systemLarge:
            return 12
        default:
            return 4
        }
    }

    private var sampleTasksMedium: [WidgetTaskItem] {
        [
            .init(id: UUID(), title: "Drink water", isDoneToday: false),
            .init(id: UUID(), title: "Workout", isDoneToday: false),
            .init(id: UUID(), title: "Read", isDoneToday: false),
            .init(id: UUID(), title: "Sleep early", isDoneToday: true),
        ]
    }
}

struct TodayTasksMediumEntryView: View {
    let entry: TodayTasksMediumEntry

    private var isMedium: Bool { entry.family == .systemMedium }

    var body: some View {
        Group {
            if entry.tasks.isEmpty {
                Text("home_empty_title")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isMedium {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.tasks) { t in
                        MediumTaskRow(task: t, compact: true)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.tasks) { t in
                        MediumTaskRow(task: t, compact: false)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .padding(isMedium ? EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10) : EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14))
        .containerBackground(Color.theme.background, for: .widget)
    }
}

private struct MediumTaskRow: View {
    let task: WidgetTaskItem
    var compact: Bool

    var body: some View {
        HStack(alignment: .center, spacing: compact ? 8 : 10) {
            Text(task.title)
                .font(.system(size: compact ? 13 : 14, weight: task.isDoneToday ? .regular : .semibold))
                .foregroundStyle(task.isDoneToday ? Color.theme.secondaryText : Color.theme.primaryText)
                .strikethrough(task.isDoneToday, pattern: .solid, color: Color.theme.secondaryText)
                .lineLimit(compact ? 1 : 2)
                .minimumScaleFactor(compact ? 0.7 : 0.75)
                .frame(maxWidth: .infinity, alignment: .leading)

            if task.isDoneToday {
                circle(isDone: true, compact: compact)
            } else {
                Button(intent: checkInIntent(for: task.id)) {
                    circle(isDone: false, compact: compact)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, compact ? 5 : 8)
        .padding(.horizontal, compact ? 10 : 12)
        .background(
            RoundedRectangle(cornerRadius: compact ? 9 : 12, style: .continuous)
                .fill(Color.theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 9 : 12, style: .continuous)
                .strokeBorder(Color.theme.divider, lineWidth: 1)
        )
    }

    private func checkInIntent(for habitID: UUID) -> CheckInHabitIntent {
        let intent = CheckInHabitIntent()
        intent.habitID = habitID.uuidString
        return intent
    }

    @ViewBuilder
    private func circle(isDone: Bool, compact: Bool) -> some View {
        let diameter: CGFloat = compact ? 20 : 24
        let hit: CGFloat = compact ? 28 : 36
        let strokeColor = isDone ? Color.theme.success : Color.theme.primaryText
        let fillColor = isDone ? Color.theme.success : Color.clear

        ZStack {
            Circle()
                .fill(fillColor)
                .frame(width: diameter, height: diameter)
            Circle()
                .strokeBorder(strokeColor, lineWidth: compact ? 1.5 : 2)
                .frame(width: diameter, height: diameter)
        }
        .frame(width: hit, height: hit)
        .contentShape(Rectangle())
    }
}

struct TodayTasksMediumWidget: Widget {
    let kind = "TodayTasksMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayTasksMediumProvider()) { entry in
            TodayTasksMediumEntryView(entry: entry)
        }
        .configurationDisplayName(Text("home_title"))
        .description(Text("widget_desc_today_interactive"))
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    TodayTasksMediumWidget()
} timeline: {
    TodayTasksMediumEntry(date: .now, family: .systemMedium, tasks: [
        .init(id: UUID(), title: "阅读", isDoneToday: false),
        .init(id: UUID(), title: "喝水", isDoneToday: true),
        .init(id: UUID(), title: "运动", isDoneToday: true),
        .init(id: UUID(), title: "记账", isDoneToday: true),
    ])
}
