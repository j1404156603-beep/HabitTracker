import AuthenticationServices
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var store: HabitStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if auth.isSignedIn {
                MainTabView()
            } else {
                signInView
            }
        }
        .onOpenURL { url in
            handleOpenURL(url)
        }
        .task {
            await auth.restoreSession()
            if auth.isSignedIn {
                if auth.isLocalMode {
                    settings.syncEnabled = false
                }
                await store.refresh()
                await settings.scheduleReminders(using: store.habits)
            }
        }
    }

    private var signInView: some View {
        VStack(spacing: 16) {
            Text("HabitTracker")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.theme.primaryText)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                auth.handleSignInCompletion(result)
                if auth.isSignedIn {
                    Task {
                        await store.refresh()
                        await settings.scheduleReminders(using: store.habits)
                    }
                }
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .black : .white)
            .frame(height: 48)
            .padding(.horizontal, 24)

            Button {
                auth.continueInLocalMode()
                settings.syncEnabled = false
                Task {
                    await store.refresh()
                    await settings.scheduleReminders(using: store.habits)
                }
            } label: {
                Text("root_local_mode_button")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.theme.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.theme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.theme.divider, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)

            Text("root_sign_in_note")
                .font(.footnote)
                .foregroundStyle(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text("root_local_mode_note")
                .font(.footnote)
                .foregroundStyle(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            #if DEBUG
            Button("root_skip_sign_in") {
                auth.signInForTesting()
            }
            .buttonStyle(.bordered)
            .tint(Color.theme.accent)
            .padding(.top, 8)
            #endif
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background.ignoresSafeArea())
    }

    private func handleOpenURL(_ url: URL) {
        guard url.scheme == "habittracker" else { return }
        if url.host == "checkin" {
            let idString = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if let uuid = UUID(uuidString: idString) {
                Task { await store.checkInHabitFromWidget(id: uuid) }
            }
        }
    }
}

