import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var id: String?
    @Published var errorMessage: String = ""
    
    private let db = Firestore.firestore()

    init() {
        checkAuthenticationStatus()
    }

    private func checkAuthenticationStatus() {
        if let user = Auth.auth().currentUser {
            id = user.uid
            isAuthenticated = true
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        errorMessage = ""

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = "Ошибка: \(error.localizedDescription)"
                completion(false)
                return
            }

            guard let user = result?.user else {
                self.errorMessage = "Не удалось войти. Проверьте данные."
                completion(false)
                return
            }

            self.isAuthenticated = true
            self.id = user.uid
            completion(true)
        }
    }
    
    func signUp(name: String, email: String, password: String, confirmPassword: String, completion: @escaping (Bool) -> Void) {
        errorMessage = ""

        // Валидация
        guard validateFields(name: name, email: email, password: password, confirmPassword: confirmPassword) else {
            completion(false)
            return
        }

        // Создание пользователя
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = "Ошибка: \(error.localizedDescription)"
                completion(false)
                return
            }

            guard let user = result?.user else {
                self.errorMessage = "Не удалось создать аккаунт"
                completion(false)
                return
            }

            self.saveUserData(user, name: name) { success in
                if success {
                    self.isAuthenticated = true
                    self.id = user.uid
                    completion(true)
                } else {
                    completion(false)
                }
            }
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
    
    private func validateFields(name: String, email: String, password: String, confirmPassword: String) -> Bool {
        if password != confirmPassword {
            errorMessage = "Пароли не совпадают"
            return false
        } else if email.isEmpty || password.isEmpty || name.isEmpty {
            errorMessage = "Все поля обязательны для заполнения"
            return false
        }
        return true
    }
    
    private func saveUserData(_ user: FirebaseAuth.User, name: String, completion: @escaping (Bool) -> Void) {
        let userData: [String: Any] = [
            "name": name,
            "email": user.email ?? ""
        ]

        db.collection("users").document(user.uid).setData(userData) { error in
            if let error = error {
                self.errorMessage = "Ошибка сохранения данных: \(error.localizedDescription)"
                completion(false)
                return
            }
            completion(true)
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
