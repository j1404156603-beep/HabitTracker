import SwiftUI

struct QuickCheckInView: View {
    @EnvironmentObject private var store: HabitStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    private var pendingHabits: [Habit] {
        store.habits.filter { !$0.isCompletedToday() }
    }

    var body: some View {
        List {
            if pendingHabits.isEmpty {
                ContentUnavailableView("quick_check_in_all_done_title", systemImage: "checkmark.circle", description: Text("quick_check_in_all_done_subtitle"))
            } else {
                Section("quick_check_in_section_title") {
                    ForEach(pendingHabits) { habit in
                        NavigationLink {
                            CheckInView(habit: habit)
                                .environmentObject(store)
                                .environmentObject(settings)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(habit.title)
                                        .foregroundStyle(Color.theme.primaryText)
                                    Text(habit.periodDisplayText)
                                        .font(.footnote)
                                        .foregroundStyle(Color.theme.secondaryText)
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .renderingMode(.template)
                                    .foregroundStyle(Color.theme.accent)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("quick_check_in_title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("quick_check_in_close") { dismiss() }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.theme.background)
        .toolbarBackground(Color.theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

