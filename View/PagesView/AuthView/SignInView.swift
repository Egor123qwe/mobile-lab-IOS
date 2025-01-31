import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var navigateBack: (() -> Void)?
    
    @State private var email = ""
    @State private var password = ""

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
            if !authViewModel.errorMessage.isEmpty {
                Text(authViewModel.errorMessage)
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
        authViewModel.signIn(email: email, password: password) { 
            success in
            
            if success {
                navigateBack?()
            }
        }
    }
}
