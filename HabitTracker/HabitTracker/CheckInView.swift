import SwiftUI

struct CheckInView: View {
    @EnvironmentObject private var store: HabitStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    let habit: Habit

    @State private var showSuccess: Bool = false

    private var isDone: Bool {
        habit.isCompletedToday()
    }

    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            VStack(spacing: 16) {
                Spacer()

                Button {
                    guard settings.syncEnabled else { return }
                    guard !isDone else { return }

                    Task {
                        var updated = habit
                        updated.checkInNow()
                        await store.upsert(updated)

                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showSuccess = true
                            }
                        }

                        try? await Task.sleep(for: .seconds(1.2))
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showSuccess = false
                            }
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isDone ? Color.theme.accent.opacity(0.55) : Color.theme.accent)
                            .frame(width: 180, height: 180)

                        Image(systemName: "checkmark")
                            .renderingMode(.template)
                            .font(.system(size: 54, weight: .bold))
                            .foregroundStyle(Color.theme.primaryText)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!settings.syncEnabled || isDone)

                Button {
                    dismiss()
                } label: {
                    Text("check_in_cancel")
                        .font(.headline)
                        .foregroundStyle(Color.theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 24)

            if showSuccess {
                SuccessPopup()
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .navigationTitle(habit.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

private struct SuccessPopup: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("check_in_success_title")
                .font(.title3.bold())
            Text("check_in_success_subtitle")
                .font(.headline)
        }
        .foregroundStyle(Color.theme.primaryText)
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .background(Color.theme.cardBackground.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.theme.divider, lineWidth: 1)
        )
    }
}

