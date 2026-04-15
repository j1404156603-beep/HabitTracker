import SwiftUI

struct CreateHabitView: View {
    @EnvironmentObject private var store: HabitStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var selectedTemplateDescription: String = ""
    @State private var periodType: PeriodType = .daily
    @State private var weeklyTimes: Int = 3
    @State private var monthlyDays: Int = 10
    @State private var useDailyTimeWindow: Bool = false
    @State private var dailyStart: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var dailyEnd: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()

    enum PeriodType: String, CaseIterable, Identifiable {
        case daily
        case weekly
        case monthly

        var id: String { rawValue }

        var label: LocalizedStringKey {
            switch self {
            case .daily: return "create_habit_cycle_daily"
            case .weekly: return "create_habit_cycle_weekly"
            case .monthly: return "create_habit_cycle_monthly"
            }
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var selectedPeriod: HabitPeriod {
        switch periodType {
        case .daily:
            return .daily
        case .weekly:
            return .weekly(timesPerWeek: weeklyTimes)
        case .monthly:
            return .monthly(daysPerMonth: monthlyDays)
        }
    }

    private func apply(template: HabitTemplate) {
        title = template.name
        selectedTemplateDescription = template.description

        // Reset time-window state when applying templates.
        useDailyTimeWindow = false

        switch template.habitPeriod {
        case .daily:
            periodType = .daily
        case .weekly(let times):
            periodType = .weekly
            weeklyTimes = times
        case .monthly(let days):
            periodType = .monthly
            monthlyDays = days
        }
    }

    private var selectedDailyWindow: DailyTimeWindow? {
        guard periodType == .daily, useDailyTimeWindow else { return nil }
        let cal = Calendar.current
        let start = cal.component(.hour, from: dailyStart) * 60 + cal.component(.minute, from: dailyStart)
        let end = cal.component(.hour, from: dailyEnd) * 60 + cal.component(.minute, from: dailyEnd)
        guard end > start else { return nil }
        return DailyTimeWindow(startMinutes: start, endMinutes: end)
    }

    var body: some View {
        Form {
            Section("create_habit_templates") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(HabitTemplate.presets) { t in
                            Button {
                                apply(template: t)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: t.icon)
                                        .font(.title3)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(t.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)

                                        Text(t.cycleType)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if !selectedTemplateDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(selectedTemplateDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("create_habit_templates_hint")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("create_habit_name_section") {
                TextField("create_habit_name_placeholder", text: $title)
                    .textInputAutocapitalization(.never)
            }

            Section("create_habit_cycle_section") {
                Picker("create_habit_cycle_picker", selection: $periodType) {
                    ForEach(PeriodType.allCases) { type in
                        Text(type.label).tag(type)
                    }
                }

                switch periodType {
                case .daily:
                    Toggle("create_habit_daily_window_toggle", isOn: $useDailyTimeWindow)

                    if useDailyTimeWindow {
                        DatePicker("create_habit_start_time", selection: $dailyStart, displayedComponents: .hourAndMinute)
                        DatePicker("create_habit_end_time", selection: $dailyEnd, displayedComponents: .hourAndMinute)
                        Text("create_habit_time_hint")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("create_habit_daily_once")
                            .foregroundStyle(.secondary)
                    }
                case .weekly:
                    Stepper("create_habit_weekly_stepper \(weeklyTimes)", value: $weeklyTimes, in: 1...7)
                case .monthly:
                    Stepper("create_habit_monthly_stepper \(monthlyDays)", value: $monthlyDays, in: 1...31)
                }
            }
        }
        .navigationTitle("create_habit_title")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("create_habit_cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("create_habit_save") {
                    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    let habit = Habit(title: trimmed, period: selectedPeriod, dailyTimeWindow: selectedDailyWindow)
                    Task {
                        await store.upsert(habit)
                        dismiss()
                    }
                }
                .disabled(!canSave)
            }
        }
    }
}

