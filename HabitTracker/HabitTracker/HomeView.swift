import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: HabitStore
    @EnvironmentObject private var settings: AppSettings

    @State private var isPresentingQuickCheckIn: Bool = false
    @State private var checkInButtonPressed: Bool = false

    private var todayHabits: [Habit] {
        store.habits
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("home_title")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.theme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    LazyVStack(spacing: 14) {
                        ForEach(todayHabits) { habit in
                            HabitCard(habit: habit)
                                .padding(.horizontal, 20)
                        }

                        if todayHabits.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "checklist")
                                    .renderingMode(.template)
                                    .foregroundStyle(Color.theme.primaryText.opacity(0.85))
                                    .font(.system(size: 24, weight: .regular))
                                Text("home_empty_title")
                                    .foregroundStyle(Color.theme.primaryText)
                                    .font(.system(size: 18, weight: .semibold))
                                Text("home_empty_subtitle")
                                    .foregroundStyle(Color.theme.secondaryText)
                                    .font(.system(size: 14, weight: .regular))
                            }
                            .padding(.top, 28)
                        }
                    }
                    .padding(.bottom, 160)
                }
            }

            Button {
                guard settings.syncEnabled else { return }
                checkInButtonPressed = true
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPresentingQuickCheckIn = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    checkInButtonPressed = false
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.theme.checkInButtonBackground)

                    Circle()
                        .strokeBorder(Color.theme.primaryText, lineWidth: 2)

                    Image(systemName: "checkmark")
                        .renderingMode(.template)
                        .foregroundStyle(Color.theme.primaryText)
                        .font(.system(size: 34, weight: .semibold))
                }
                .frame(width: 120, height: 120)
                .scaleEffect(checkInButtonPressed ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: checkInButtonPressed)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 22)
            .accessibilityLabel(Text("home_check_in"))
            .disabled(!settings.syncEnabled)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $isPresentingQuickCheckIn) {
            NavigationStack { QuickCheckInView() }
                .tint(Color.theme.accent)
        }
    }
}

private struct HabitCard: View {
    @EnvironmentObject private var store: HabitStore
    @EnvironmentObject private var settings: AppSettings

    let habit: Habit

    private var isDone: Bool {
        habit.isCompletedToday()
    }

    var body: some View {
        Button {
            guard settings.syncEnabled else { return }
            guard !isDone else { return }
            Task {
                var updated = habit
                updated.checkInNow()
                await store.upsert(updated)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isDone ? "checkmark.circle" : "circle")
                    .renderingMode(.template)
                    .foregroundStyle(isDone ? Color.theme.primaryText : Color.theme.secondaryText)
                    .font(.system(size: 20, weight: .regular))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 6) {
                    Text(habit.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.theme.primaryText)

                    Text(habit.periodDisplayText)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.theme.secondaryText)
                }

                Spacer()

                Text(isDone ? LocalizedStringKey("home_done") : LocalizedStringKey("home_pending"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isDone ? Color.theme.primaryText : Color.theme.danger)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.theme.background)
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(
                                isDone
                                    ? Color.theme.accent
                                    : Color.theme.divider,
                                lineWidth: 1
                            )
                    )
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isDone
                            ? Color.theme.accent.opacity(0.35)
                            : Color.theme.divider,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

