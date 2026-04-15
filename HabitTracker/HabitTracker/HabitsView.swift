import SwiftUI

struct HabitsView: View {
    @EnvironmentObject private var store: HabitStore
    @EnvironmentObject private var settings: AppSettings

    @State private var isPresentingCreateHabit: Bool = false
    @State private var isShowingSyncDisabledAlert: Bool = false

    var body: some View {
        List {
            Section("habits_section_title") {
                ForEach(store.habits) { habit in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(habit.title)
                                .foregroundStyle(Color.theme.primaryText)
                            Text(habit.periodDisplayText)
                                .font(.footnote)
                                .foregroundStyle(Color.theme.secondaryText)
                        }
                        Spacer()
                        Image(systemName: habit.isCompletedToday() ? "checkmark.circle" : "circle")
                            .renderingMode(.template)
                            .foregroundStyle(habit.isCompletedToday() ? Color.theme.success : Color.theme.danger)
                    }
                    .listRowBackground(Color.theme.cardBackground)
                }
                .onDelete { indexSet in
                    guard settings.syncEnabled else { return }
                    let toDelete = indexSet.map { store.habits[$0] }
                    Task { for h in toDelete { await store.delete(h) } }
                }
            }
        }
        .navigationTitle("habits_title")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("habits_sync") {
                    guard settings.syncEnabled else {
                        isShowingSyncDisabledAlert = true
                        return
                    }
                    Task { await store.refresh() }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    guard settings.syncEnabled else {
                        isShowingSyncDisabledAlert = true
                        return
                    }
                    isPresentingCreateHabit = true
                } label: {
                    Image(systemName: "plus")
                        .renderingMode(.template)
                }
            }
        }
        .refreshable {
            guard settings.syncEnabled else {
                isShowingSyncDisabledAlert = true
                return
            }
            await store.refresh()
        }
        .sheet(isPresented: $isPresentingCreateHabit) {
            NavigationStack { CreateHabitView() }
                .tint(Color.theme.accent)
        }
        .alert("habits_sync_disabled_title", isPresented: $isShowingSyncDisabledAlert) {
            Button("habits_sync_disabled_ok", role: .cancel) {}
        } message: {
            Text("habits_sync_disabled_message")
        }
        .scrollContentBackground(.hidden)
        .background(Color.theme.background)
        .toolbarBackground(Color.theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

