import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            if authViewModel.isAuthenticated {
                MainView().environmentObject(authViewModel)
            } else {
                StartScreenView().environmentObject(authViewModel)
            }
        }
    }
}

