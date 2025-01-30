import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            contentView
        }
    }
    
    private var contentView: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainView()
            } else {
                StartScreenView()
            }
        }
        .environmentObject(authViewModel) // Применяем только один раз для всех представлений
    }
}
