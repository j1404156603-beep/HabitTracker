import AuthenticationServices
import Combine
import Foundation

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var appleUserID: String?
    @Published private(set) var isLocalMode: Bool = false

    private let keychainService = "HabitTracker.Auth"
    private let keychainAccount = "appleUserID"
    private let localModeKey = "auth.localMode"

    func restoreSession() async {
        if UserDefaults.standard.bool(forKey: localModeKey) {
            isLocalMode = true
            appleUserID = nil
            isSignedIn = true
            return
        }

        guard let stored = KeychainHelper.load(service: keychainService, account: keychainAccount) else {
            isSignedIn = false
            appleUserID = nil
            isLocalMode = false
            return
        }

        let provider = ASAuthorizationAppleIDProvider()
        let state = await withCheckedContinuation { continuation in
            provider.getCredentialState(forUserID: stored) { state, _ in
                continuation.resume(returning: state)
            }
        }

        switch state {
        case .authorized:
            appleUserID = stored
            isLocalMode = false
            isSignedIn = true
        default:
            KeychainHelper.delete(service: keychainService, account: keychainAccount)
            appleUserID = nil
            isLocalMode = false
            isSignedIn = false
        }
    }

    func handleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure:
            isSignedIn = false
            appleUserID = nil
            isLocalMode = false
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                isSignedIn = false
                appleUserID = nil
                isLocalMode = false
                return
            }

            let userID = credential.user
            do {
                try KeychainHelper.save(userID, service: keychainService, account: keychainAccount)
                appleUserID = userID
                isLocalMode = false
                UserDefaults.standard.set(false, forKey: localModeKey)
                isSignedIn = true
            } catch {
                isSignedIn = false
                appleUserID = nil
                isLocalMode = false
            }
        }
    }

    func continueInLocalMode() {
        KeychainHelper.delete(service: keychainService, account: keychainAccount)
        appleUserID = nil
        isLocalMode = true
        isSignedIn = true
        UserDefaults.standard.set(true, forKey: localModeKey)
    }

    func signOut() {
        KeychainHelper.delete(service: keychainService, account: keychainAccount)
        UserDefaults.standard.set(false, forKey: localModeKey)
        isSignedIn = false
        appleUserID = nil
        isLocalMode = false
    }

    #if DEBUG
    func signInForTesting() {
        appleUserID = "TEST_USER"
        isSignedIn = true
    }
    #endif
}

