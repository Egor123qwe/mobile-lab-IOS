import Foundation
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var id: String = ""
    
    init() {
        isAuthenticated = Auth.auth().currentUser != nil
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
        } catch {
            print("Ошибка выхода: \(error.localizedDescription)")
        }
    }
}
