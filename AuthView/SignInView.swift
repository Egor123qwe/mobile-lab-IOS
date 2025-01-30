import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var navigateBack: (() -> Void)?
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    
    var body: some View {
        VStack {
            Text("Войти")
                .font(.largeTitle)
                .padding(.bottom, 20)
            
            inputField(title: "Email", text: $email)
            secureInputField(title: "Пароль", text: $password)
            
            errorMessageView
            
            signInButton
            
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
    
    private var signInButton: some View {
        Button(action: handleSignIn) {
            Text("Войти")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
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
    
    private func handleSignIn() {
        errorMessage = ""
        
        if !validateFields() {
            return
        }
        
        signIn()
    }
    
    private func validateFields() -> Bool {
        if email.isEmpty || password.isEmpty {
            errorMessage = "Пожалуйста, заполните все поля"
            return false
        }
        return true
    }
    
    private func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "Ошибка: \(error.localizedDescription)"
                return
            }
            
            guard let user = result?.user else {
                errorMessage = "Не удалось войти. Проверьте данные."
                return
            }
            
            authViewModel.isAuthenticated = true
            authViewModel.id = user.uid
            navigateBack?()
        }
    }
}
