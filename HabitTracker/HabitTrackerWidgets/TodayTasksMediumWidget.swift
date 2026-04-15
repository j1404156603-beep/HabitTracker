import AppIntents
import SwiftUI
import WidgetKit

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
            return 6
        case .systemLarge:
            return 8
        default:
            return 6
        }
    }

    private var sampleTasksMedium: [WidgetTaskItem] {
        [
            .init(id: UUID(), title: "阅读", icon: "book", isDoneToday: false),
            .init(id: UUID(), title: "喝水", icon: "drop", isDoneToday: false),
            .init(id: UUID(), title: "运动", icon: "figure.walk", isDoneToday: true),
            .init(id: UUID(), title: "记账", icon: "pencil", isDoneToday: true),
        ]
    }
}

struct TodayTasksMediumEntryView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: TodayTasksMediumEntry

    private var isMedium: Bool { entry.family == .systemMedium }
    private var isLarge: Bool { entry.family == .systemLarge }
    private var isMediumDense: Bool { isMedium && entry.tasks.count >= 5 }
    private var mediumTasks: [WidgetTaskItem] { Array(entry.tasks.prefix(6)) }
    private var useGrid: Bool {
        if isMedium { return mediumTasks.count > 3 }
        if isLarge { return entry.tasks.count > 4 }
        return false
    }
    private var widgetBackground: Color {
        colorScheme == .dark ? Color(light: 0x000000, dark: 0x000000) : Color(light: 0xF2F2F7, dark: 0x000000)
    }
    private var cardBackground: Color {
        colorScheme == .dark ? Color(light: 0x1A1A1A, dark: 0x1A1A1A) : Color(light: 0xFFFFFF, dark: 0x1A1A1A)
    }

    var body: some View {
        VStack(alignment: .center, spacing: isLarge ? 16 : 12) {
            if entry.tasks.isEmpty {
                Text("home_empty_title")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isMedium {
                Group {
                    if useGrid {
                        let columns = [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                        ]
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(mediumTasks) { t in
                                TaskRow(
                                    task: t,
                                    family: .systemMedium,
                                    cardBackground: cardBackground,
                                    dense: isMediumDense
                                )
                            }
                        }
                    } else {
                        VStack(alignment: .center, spacing: 12) {
                            ForEach(mediumTasks) { t in
                                TaskRow(
                                    task: t,
                                    family: .systemMedium,
                                    cardBackground: cardBackground,
                                    dense: false
                                )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else if useGrid {
                let columns = [
                    GridItem(.flexible(), spacing: isLarge ? 12 : 10),
                    GridItem(.flexible(), spacing: isLarge ? 12 : 10)
                ]
                LazyVGrid(columns: columns, spacing: isLarge ? 16 : 12) {
                    ForEach(entry.tasks) { t in
                        TaskRow(
                            task: t,
                            family: entry.family,
                            cardBackground: cardBackground,
                            dense: false
                        )
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: isLarge ? 16 : 12) {
                    ForEach(entry.tasks) { t in
                        TaskRow(
                            task: t,
                            family: entry.family,
                            cardBackground: cardBackground,
                            dense: false
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, isLarge ? 16 : 14)
        .padding(.vertical, isMedium ? 16 : (isLarge ? 16 : 14))
        .containerBackground(widgetBackground, for: .widget)
    }
}

private struct TaskRow: View {
    let task: WidgetTaskItem
    let family: WidgetFamily
    let cardBackground: Color
    var dense: Bool = false

    private var isLarge: Bool { family == .systemLarge }
    private var titleSize: CGFloat {
        if isLarge { return 14 }
        return dense ? 12 : 13
    }
    private var iconSize: CGFloat {
        if isLarge { return 20 }
        return dense ? 14 : 15
    }
    private var rowVerticalPadding: CGFloat {
        if isLarge { return 10 }
        return dense ? 7 : 8
    }
    private var horizontalPadding: CGFloat {
        if isLarge { return 12 }
        return dense ? 9 : 10
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: task.icon)
                .font(.system(size: iconSize, weight: .regular))
                .foregroundStyle(task.isDoneToday ? Color.theme.secondaryText : Color.theme.accent)
                .frame(width: isLarge ? 20 : (dense ? 15 : 16))

            Text(task.title)
                .font(.system(size: titleSize, weight: task.isDoneToday ? .regular : .semibold))
                .foregroundStyle(task.isDoneToday ? Color.theme.secondaryText : Color.theme.accent)
                .strikethrough(task.isDoneToday, pattern: .solid, color: Color.theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .leading)

            if family == .systemMedium {
                if task.isDoneToday {
                    circle(isDone: true, compact: true, dense: dense)
                } else {
                    Button(intent: checkInIntent(for: task.id)) {
                        circle(isDone: false, compact: true, dense: dense)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                circle(isDone: task.isDoneToday, compact: false, dense: false)
            }
        }
        .padding(.vertical, rowVerticalPadding)
        .padding(.horizontal, horizontalPadding)
        .background(
            RoundedRectangle(cornerRadius: isLarge ? 12 : 10, style: .continuous)
                .fill(cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isLarge ? 12 : 10, style: .continuous)
                .strokeBorder(Color.theme.divider, lineWidth: 1)
        )
    }

    private func checkInIntent(for habitID: UUID) -> CheckInHabitIntent {
        let intent = CheckInHabitIntent()
        intent.habitID = habitID.uuidString
        return intent
    }

    @ViewBuilder
    private func circle(isDone: Bool, compact: Bool, dense: Bool) -> some View {
        let diameter: CGFloat = compact ? 20 : 24
        let hit: CGFloat = compact ? (dense ? 24 : 26) : 34
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
        .init(id: UUID(), title: "阅读", icon: "book", isDoneToday: false),
        .init(id: UUID(), title: "喝水", icon: "drop", isDoneToday: true),
        .init(id: UUID(), title: "运动", icon: "figure.walk", isDoneToday: false),
        .init(id: UUID(), title: "记账", icon: "pencil", isDoneToday: true),
        .init(id: UUID(), title: "冥想", icon: "brain.head.profile", isDoneToday: false),
    ])
}

#Preview(as: .systemLarge) {
    TodayTasksMediumWidget()
} timeline: {
    TodayTasksMediumEntry(date: .now, family: .systemLarge, tasks: [
        .init(id: UUID(), title: "阅读", icon: "book", isDoneToday: false),
        .init(id: UUID(), title: "喝水", icon: "drop", isDoneToday: true),
        .init(id: UUID(), title: "运动", icon: "figure.walk", isDoneToday: false),
        .init(id: UUID(), title: "记账", icon: "pencil", isDoneToday: true),
        .init(id: UUID(), title: "冥想", icon: "brain.head.profile", isDoneToday: false),
    ])
}
