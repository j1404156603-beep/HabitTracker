import Charts
import SwiftUI

struct CheckInTrendChartView: View {
    @EnvironmentObject private var store: HabitStore

    struct DailyCount: Identifiable, Equatable {
        var id: Date { day }
        let day: Date
        let count: Int
    }

    private var last30Days: [DailyCount] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -29, to: today) ?? today

        var countsByDay: [Date: Int] = [:]
        for habit in store.habits {
            for completion in habit.completions {
                let day = calendar.startOfDay(for: completion)
                guard day >= start && day <= today else { continue }
                countsByDay[day, default: 0] += 1
            }
        }

        return (0..<30).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return DailyCount(day: day, count: countsByDay[day, default: 0])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart(last30Days) { item in
                BarMark(
                    x: .value("trend_axis_date", item.day),
                    y: .value("trend_axis_check_in_count", item.count)
                )
                .foregroundStyle(.tint)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 5)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 260)

            Text("check_in_trend_caption")
                .font(.footnote)
                .foregroundStyle(Color.theme.secondaryText)
        }
        .padding()
        .navigationTitle("check_in_trend_title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

