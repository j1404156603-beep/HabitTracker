import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: HabitStore

    @State private var isShowingSignOutDialog: Bool = false
    @State private var isShowingLanguageSheet: Bool = false

    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("settings_title")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.theme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 14)

                    TeslaCard {
                        TeslaAppearanceSegment(
                            selection: Binding(
                                get: { settings.appearance },
                                set: { settings.appearance = $0 }
                            )
                        )
                    }

                    TeslaCard {
                        TeslaRowButton(
                            icon: "globe",
                            title: "settings_language",
                            value: settings.language.displayNameKey
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowingLanguageSheet = true
                            }
                        }
                    }

                    TeslaCard {
                        TeslaRowToggle(icon: "bell", title: "settings_notifications", isOn: $settings.notificationsEnabled)
                        TeslaDivider()
                        TeslaRowToggle(icon: "arrow.triangle.2.circlepath", title: "settings_sync", isOn: $settings.syncEnabled)
                    }

                    TeslaCard {
                        NavigationLink {
                            AboutView()
                        } label: {
                            TeslaRow(
                                icon: "info.circle",
                                title: "settings_about",
                                value: nil,
                                showsChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    TeslaOutlineButton(title: "settings_sign_out") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isShowingSignOutDialog = true
                        }
                    }
                    .padding(.top, 6)

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }

            if isShowingLanguageSheet {
                TeslaSheet(title: "settings_language") {
                    VStack(spacing: 10) {
                        ForEach(AppSettings.AppLanguage.allCases) { lang in
                            TeslaSheetOption(
                                title: lang.displayNameKey,
                                isSelected: settings.language == lang
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    settings.language = lang
                                }
                            }
                        }
                    }
                } onDismiss: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isShowingLanguageSheet = false
                    }
                }
                .transition(.opacity)
            }

            if isShowingSignOutDialog {
                TeslaDialog(
                    title: "dialog_sign_out_title",
                    buttons: [
                        .init(title: "dialog_sign_out_clear", role: .danger) {
                            Task {
                                await store.deleteAllHabits()
                                await MainActor.run { auth.signOut() }
                                await MainActor.run {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isShowingSignOutDialog = false
                                    }
                                }
                            }
                        },
                        .init(title: "dialog_sign_out_keep", role: .success) {
                            auth.signOut()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowingSignOutDialog = false
                            }
                        },
                        .init(title: "dialog_cancel", role: .neutral) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowingSignOutDialog = false
                            }
                        }
                    ]
                )
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
    }
}

private struct TeslaAppearanceSegment: View {
    @Binding var selection: AppSettings.Appearance

    private let options: [AppSettings.Appearance] = [.light, .dark, .system]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TeslaSectionTitle("settings_appearance")

            HStack(spacing: 10) {
                ForEach(options) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = option
                        }
                    } label: {
                        Text(option.labelKey)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(selection == option ? Color.theme.primaryText : Color.theme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(selection == option ? Color.theme.checkInButtonBackground : Color.clear)
                            )
                            .overlay(
                                Group {
                                    if selection == option {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(Color.theme.primaryText, lineWidth: 1)
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct TeslaCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.theme.divider, lineWidth: 1)
        )
    }
}

private struct TeslaSectionTitle: View {
    let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.theme.secondaryText)
    }
}

private struct TeslaDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.theme.divider)
            .frame(height: 1)
            .opacity(0.6)
            .padding(.leading, 34)
    }
}

private struct TeslaRow: View {
    let icon: String
    let title: LocalizedStringKey
    let value: LocalizedStringKey?
    let showsChevron: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .renderingMode(.template)
                .foregroundStyle(Color.theme.primaryText)
                .font(.system(size: 18, weight: .regular))
                .frame(width: 22)

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.theme.primaryText)

            Spacer()

            if let value {
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.theme.secondaryText)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .renderingMode(.template)
                    .foregroundStyle(Color.theme.secondaryText)
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .contentShape(Rectangle())
    }
}

private struct TeslaRowButton: View {
    let icon: String
    let title: LocalizedStringKey
    let value: LocalizedStringKey?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            TeslaRow(icon: icon, title: title, value: value, showsChevron: true)
        }
        .buttonStyle(.plain)
    }
}

private struct TeslaRowToggle: View {
    let icon: String
    let title: LocalizedStringKey
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .renderingMode(.template)
                .foregroundStyle(Color.theme.primaryText)
                .font(.system(size: 18, weight: .regular))
                .frame(width: 22)

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.theme.primaryText)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.theme.accent)
        }
    }
}

private struct TeslaOutlineButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.theme.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.theme.primaryText, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct TeslaDialog: View {
    struct DialogButton: Identifiable {
        enum Role { case danger, success, neutral }

        let id = UUID()
        let title: LocalizedStringKey
        let role: Role
        let action: () -> Void
    }

    let title: LocalizedStringKey
    let buttons: [DialogButton]

    var body: some View {
        ZStack {
            Color.theme.scrim.ignoresSafeArea()

            VStack(spacing: 14) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.theme.primaryText)

                VStack(spacing: 10) {
                    ForEach(buttons) { b in
                        Button(action: b.action) {
                            Text(b.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(foreground(for: b.role))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Color.theme.primaryText, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.theme.cardBackground)
            )
        }
    }

    private func foreground(for role: DialogButton.Role) -> Color {
        switch role {
        case .danger: return Color.theme.danger
        case .success: return Color.theme.success
        case .neutral: return Color.theme.secondaryText
        }
    }
}

private struct TeslaSheet<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.theme.scrim.ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.theme.primaryText)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .renderingMode(.template)
                            .foregroundStyle(Color.theme.secondaryText)
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }

                content
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.theme.divider, lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
    }
}

private struct TeslaSheetOption: View {
    let title: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isSelected ? Color.theme.primaryText : Color.theme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? Color.theme.checkInButtonBackground : Color.clear)
                )
                .overlay(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.theme.primaryText, lineWidth: 1)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
}


