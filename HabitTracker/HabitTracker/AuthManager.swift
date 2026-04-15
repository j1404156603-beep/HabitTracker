import AuthenticationServices
import Combine
import Foundation

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var appleUserID: String?

    private let keychainService = "HabitTracker.Auth"
    private let keychainAccount = "appleUserID"

    func restoreSession() async {
        guard let stored = KeychainHelper.load(service: keychainService, account: keychainAccount) else {
            isSignedIn = false
            appleUserID = nil
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
            isSignedIn = true
        default:
            KeychainHelper.delete(service: keychainService, account: keychainAccount)
            appleUserID = nil
            isSignedIn = false
        }
    }

    func handleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure:
            isSignedIn = false
            appleUserID = nil
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                isSignedIn = false
                appleUserID = nil
                return
            }

            let userID = credential.user
            do {
                try KeychainHelper.save(userID, service: keychainService, account: keychainAccount)
                appleUserID = userID
                isSignedIn = true
            } catch {
                isSignedIn = false
                appleUserID = nil
            }
        }
    }

    func signOut() {
        KeychainHelper.delete(service: keychainService, account: keychainAccount)
        isSignedIn = false
        appleUserID = nil
    }

    #if DEBUG
    func signInForTesting() {
        appleUserID = "TEST_USER"
        isSignedIn = true
    }
    #endif
}

