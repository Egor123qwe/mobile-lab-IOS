import SwiftUI

struct StartScreenView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var navigationPath = NavigationPath() // Управление навигацией
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                Spacer()
                
                Text("Добро пожаловать!")
                    .font(.largeTitle)
                    .padding(.bottom, 20)
                
                Text("Создайте аккаунт или войдите в существующий, чтобы продолжить.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                Button("Войти") {
                    navigateToSignIn()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal, 40)
                .padding(.top, 10)
                
                Button("Создать аккаунт") {
                    navigateToSignUp()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal, 40)
                
                Spacer()
                
            }
            .navigationDestination(for: String.self) { route in
                if route == "SignIn" {
                    SignInView(navigateBack: navigateBack).environmentObject(authViewModel)
                } else if route == "SignUp" {
                    SignUpView(navigateBack: navigateBack).environmentObject(authViewModel)
                }
            }
        }
    }
    
    private func navigateToSignIn() {
        navigationPath.append("SignIn") // Переход на страницу входа
    }
    
    private func navigateToSignUp() {
        navigationPath.append("SignUp") // Переход на страницу регистрации
    }
    
    private func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast() // Удаление последнего маршрута
        }
    }
}
