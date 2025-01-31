import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var navigateBack: (() -> Void)?
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

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
            if !authViewModel.errorMessage.isEmpty {
                Text(authViewModel.errorMessage)
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
        authViewModel.signUp(name: name, email: email, password: password, confirmPassword: confirmPassword) { success in
            if success {
                navigateBack?()
            }
        }
    }
}
