import Charts
import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: HabitStore
    @State private var isShowingShare: Bool = false
    @Environment(\.locale) private var locale

    struct DailyRate: Identifiable, Equatable {
        var id: Date { day }
        let day: Date
        let rate: Double // 0...1
    }

    private var calendar: Calendar { .current }

    private var last30DaysRates: [DailyRate] {
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -29, to: today) ?? today
        let totalHabits = max(store.habits.count, 0)

        return (0..<30).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            guard totalHabits > 0 else { return DailyRate(day: day, rate: 0) }

            let completedCount = store.habits.reduce(0) { partial, habit in
                partial + (habit.completions.contains(where: { calendar.isDate($0, inSameDayAs: day) }) ? 1 : 0)
            }

            return DailyRate(day: day, rate: Double(completedCount) / Double(totalHabits))
        }
    }

    private var currentStreakDays: Int {
        let today = calendar.startOfDay(for: Date())

        func didAnyCheckIn(on day: Date) -> Bool {
            store.habits.contains(where: { habit in
                habit.completions.contains(where: { calendar.isDate($0, inSameDayAs: day) })
            })
        }

        var streak = 0
        var cursor = today
        while didAnyCheckIn(on: cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    private var bestCheckInTimeText: String {
        let completions = store.habits.flatMap(\.completions)
        guard !completions.isEmpty else { return "-" }

        var countsByHour: [Int: Int] = [:]
        for d in completions {
            let hour = calendar.component(.hour, from: d)
            countsByHour[hour, default: 0] += 1
        }

        guard let bestHour = countsByHour.max(by: { $0.value < $1.value })?.key else { return "-" }
        return formatHourText(bestHour)
    }

    private var shareText: String {
        let todayRate = last30DaysRates.last?.rate ?? 0
        let percent = Int((todayRate * 100).rounded())
        let format = String(localized: "stats_share_text", locale: locale)
        return String(format: format, currentStreakDays, percent, bestCheckInTimeText)
    }

    var body: some View {
        List {
            Section("stats_section_streak") {
                Chart {
                    BarMark(
                        x: .value("stats_axis_item", String(localized: "stats_axis_current", locale: locale)),
                        y: .value("stats_axis_days", currentStreakDays)
                    )
                    .foregroundStyle(Color.theme.success)
                }
                .frame(height: 180)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.theme.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.theme.divider, lineWidth: 1)
                )

                Text("stats_streak_text \(currentStreakDays)")
                    .foregroundStyle(Color.theme.secondaryText)
            }

            Section("stats_section_trend") {
                Chart(last30DaysRates) { item in
                    LineMark(
                        x: .value("stats_axis_date", item.day),
                        y: .value("stats_axis_completion_rate", item.rate)
                    )
                    .foregroundStyle(Color.theme.accent)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("stats_axis_date", item.day),
                        y: .value("stats_axis_completion_rate", item.rate)
                    )
                    .foregroundStyle(Color.theme.accent.opacity(0.65))
                    .symbolSize(12)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        if let v = value.as(Double.self) {
                            AxisValueLabel("\(Int((v * 100).rounded()))%")
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: 240)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.theme.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.theme.divider, lineWidth: 1)
                )
            }

            Section("stats_section_best_time") {
                Text(bestCheckInTimeText)
                    .font(.title3.bold())
                    .foregroundStyle(Color.theme.primaryText)
            }

            Section {
                Button {
                    isShowingShare = true
                } label: {
                    Label("stats_share", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationTitle("stats_title")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingShare) {
            ShareSheet(items: [shareText])
        }
        .scrollContentBackground(.hidden)
        .background(Color.theme.background)
        .toolbarBackground(Color.theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func formatHourText(_ hour: Int) -> String {
        let h = ((hour % 24) + 24) % 24
        let (prefixKey, displayHour): (String, Int) = {
            switch h {
            case 0..<6: return ("time_prefix_dawn", h == 0 ? 12 : h)
            case 6..<12: return ("time_prefix_morning", h)
            case 12..<18: return ("time_prefix_afternoon", h == 12 ? 12 : (h - 12))
            default: return ("time_prefix_evening", h - 12)
            }
        }()
        let prefix = String(localized: String.LocalizationValue(prefixKey), locale: locale)
        let suffix = String(localized: "time_clock_suffix", locale: locale)
        return "\(prefix)\(displayHour)\(suffix)"
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

