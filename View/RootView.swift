import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            authMiddleware
        }
    }
    
    private var authMiddleware: some View {
        Group {
            if authViewModel.isAuthenticated {
                AppView()
            } else {
                EntryPointView()
            }
        }.environmentObject(authViewModel)
    }
}
