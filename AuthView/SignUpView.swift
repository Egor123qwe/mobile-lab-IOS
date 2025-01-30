import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var navigateBack: (() -> Void)?
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack {
            Text("Создать аккаунт")
                .font(.largeTitle)
                .padding(.bottom, 20)
            
            inputField(title: "Имя", text: $name)
            inputField(title: "Email", text: $email)
            secureInputField(title: "Пароль", text: $password)
            secureInputField(title: "Подтвердите пароль", text: $confirmPassword)
            
            errorMessageView
            
            createAccountButton
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    private var errorMessageView: some View {
        Group {
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 10)
            }
        }
    }
    
    private var createAccountButton: some View {
        Button(action: handleSignUp) {
            Text("Создать")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(.top, 20)
    }
    
    private func inputField(title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.top, 10)
    }
    
    private func secureInputField(title: String, text: Binding<String>) -> some View {
        SecureField(title, text: text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.top, 10)
    }
    
    private func handleSignUp() {
        errorMessage = ""
        
        // Валидация
        if !validateFields() {
            return
        }
        
        signUp()
    }
    
    private func validateFields() -> Bool {
        if password != confirmPassword {
            errorMessage = "Пароли не совпадают"
            return false
        } else if email.isEmpty || password.isEmpty || name.isEmpty {
            errorMessage = "Все поля обязательны для заполнения"
            return false
        }
        return true
    }
    
    private func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "Ошибка: \(error.localizedDescription)"
                return
            }
            
            guard let user = result?.user else { return }
            saveUserData(user)
        }
    }
    
    private func saveUserData(_ user: FirebaseAuth.User) {
        let userData: [String: Any] = [
            "name": name,
            "email": email
        ]
        
        db.collection("users").document(user.uid).setData(userData) { error in
            if let error = error {
                errorMessage = "Ошибка сохранения данных: \(error.localizedDescription)"
            }
        }
        
        navigateBack?()
    }
}
