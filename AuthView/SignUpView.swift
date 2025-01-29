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
            
            TextField("Имя", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 40)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 40)
                .padding(.top, 10)
            
            SecureField("Пароль", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 40)
                .padding(.top, 10)
            
            SecureField("Подтвердите пароль", text: $confirmPassword)
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
                
                if password != confirmPassword {
                    errorMessage = "Пароли не совпадают"
                } else if email.isEmpty || password.isEmpty || name.isEmpty {
                    errorMessage = "Все поля обязательны для заполнения"
                } else {
                    signUp()
                }
            }) {
                Text("Создать")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
            }
            
            Spacer()
        }
    }
    
    private func signUp() {
           Auth.auth().createUser(withEmail: email, password: password) { 
               result, error in
               if let error = error {
                   errorMessage = "Ошибка: \(error.localizedDescription)"
                   return
               }
               
               if let user = result?.user {
                   let userData: [String: Any] = [
                       "name": name,
                       "email": email
                   ]
                   
                   db.collection("users").document(user.uid).setData(userData) { error in
                        if let error = error {
                            errorMessage = "Ошибка сохранения данных: \(error.localizedDescription)"
                            
                            return
                        }
                    }
               }
               
               navigateBack?()
           }
       }
}


