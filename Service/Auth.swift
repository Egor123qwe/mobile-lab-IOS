import Foundation
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var id: String? // Сделано опциональным

    init() {
        if let user = Auth.auth().currentUser {
            self.id = user.uid
            self.isAuthenticated = true
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            id = nil // Обнуляем id при выходе
        } catch {
            print("Ошибка выхода: \(error.localizedDescription)")
        }
    }
}
