import Foundation

struct HabitTemplate: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()

    /// 习惯名称（如“喝水”）
    var name: String

    /// SF Symbols 图标名（如“drop.fill”）
    var icon: String

    /// 周期类型（如“每天”“每周3次”）
    var cycleType: String

    /// 习惯描述（如“每天喝8杯水”）
    var description: String
}

extension HabitTemplate {
    /// 将模板周期文本尽可能映射到现有 `HabitPeriod`
    var habitPeriod: HabitPeriod {
        // 允许输入：每天 / 每周3次 / 每周 3 次 / 每月10天 / 每月 10 天
        let normalized = cycleType
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if normalized == "每天" {
            return .daily
        }

        if normalized.hasPrefix("每周"), normalized.hasSuffix("次") {
            let n = normalized
                .replacingOccurrences(of: "每周", with: "")
                .replacingOccurrences(of: "次", with: "")
            if let times = Int(n), (1...7).contains(times) {
                return .weekly(timesPerWeek: times)
            }
        }

        if normalized.hasPrefix("每月"), normalized.hasSuffix("天") {
            let n = normalized
                .replacingOccurrences(of: "每月", with: "")
                .replacingOccurrences(of: "天", with: "")
            if let days = Int(n), (1...31).contains(days) {
                return .monthly(daysPerMonth: days)
            }
        }

        return .daily
    }

    static let presets: [HabitTemplate] = [
        HabitTemplate(
            name: "喝水",
            icon: "drop.fill",
            cycleType: "每天",
            description: "每天喝 8 杯水"
        ),
        HabitTemplate(
            name: "运动",
            icon: "figure.run",
            cycleType: "每周 3 次",
            description: "每周至少运动 3 次"
        ),
        HabitTemplate(
            name: "阅读",
            icon: "book.fill",
            cycleType: "每天",
            description: "每天阅读 20 分钟"
        ),
        HabitTemplate(
            name: "早睡",
            icon: "moon.zzz.fill",
            cycleType: "每天",
            description: "23:00 前上床睡觉"
        ),
        HabitTemplate(
            name: "记账",
            icon: "creditcard.fill",
            cycleType: "每天",
            description: "记录当天消费"
        )
    ]
}

