import Foundation
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var id: String?

    init() {
        checkAuthenticationStatus()
    }

    private func checkAuthenticationStatus() {
        if let user = Auth.auth().currentUser {
            id = user.uid
            isAuthenticated = true
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            resetAuthenticationState()
        } catch {
            handleSignOutError(error)
        }
    }

    private func resetAuthenticationState() {
        isAuthenticated = false
        id = nil
    }

    private func handleSignOutError(_ error: Error) {
        print("Ошибка выхода: \(error.localizedDescription)")
    }
}
