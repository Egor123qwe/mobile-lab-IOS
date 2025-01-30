import SwiftUI

struct StartScreenView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var navigationPath = NavigationPath() // Управление навигацией
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                Spacer()
                
                welcomeText
                
                navigationButtons
                
                Spacer()
            }
            .navigationDestination(for: String.self) { route in
                // Рендерим представление на основе маршрута
                renderDestination(for: route)
            }
        }
    }
    
    private var welcomeText: some View {
        VStack {
            Text("Добро пожаловать!")
                .font(.largeTitle)
                .padding(.bottom, 20)
            
            Text("Создайте аккаунт или войдите в существующий, чтобы продолжить.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var navigationButtons: some View {
        VStack {
            button(title: "Войти", action: navigateToSignIn)
            
            button(title: "Создать аккаунт", action: navigateToSignUp)
        }
    }
    
    private func button(title: String, action: @escaping () -> Void) -> some View {
        Button(title) {
            action()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(title == "Войти" ? Color.blue : Color.green)
        .foregroundColor(.white)
        .cornerRadius(10)
        .padding(.horizontal, 40)
        .padding(.top, 10)
    }
    
    private func navigateToSignIn() {
        navigationPath.append("SignIn") // Переход на страницу входа
    }
    
    private func navigateToSignUp() {
        navigationPath.append("SignUp") // Переход на страницу регистрации
    }
    
    private func renderDestination(for route: String) -> some View {
        switch route {
        case "SignIn":
            return AnyView(SignInView(navigateBack: navigateBack).environmentObject(authViewModel))
        case "SignUp":
            return AnyView(SignUpView(navigateBack: navigateBack).environmentObject(authViewModel))
        default:
            return AnyView(EmptyView())
        }
    }
    
    private func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast() // Удаление последнего маршрута
        }
    }
}
