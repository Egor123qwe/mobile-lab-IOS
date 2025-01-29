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
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 40)
            
            SecureField("Пароль", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 40)
                .padding(.top, 10)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 10)
            }
            
            Button(action: {
                errorMessage = ""
                
                if email.isEmpty || password.isEmpty {
                    errorMessage = "Пожалуйста, заполните все поля"
                } else {
                    signIn()
                }
            }) {
                Text("Войти")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
            }
            
            Spacer()
        }
    }
    
    private func signIn() {
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    errorMessage = "Ошибка: \(error.localizedDescription)"
                    return
                }
                
                if let user = result?.user {
                    authViewModel.isAuthenticated = true
                    authViewModel.id = user.uid
                    navigateBack?()
                } else {
                    errorMessage = "Не удалось войти. Проверьте данные."
                }
            }
        }
}
