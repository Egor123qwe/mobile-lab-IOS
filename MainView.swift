import SwiftUI

struct MainView: View {
    @State private var selectedTab: Tab = .products
    @EnvironmentObject var authViewModel: AuthViewModel
    
    enum Tab {
        case profile, products, favorites
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            RouterView(selectedTab: $selectedTab).padding(.top, 50).environmentObject(authViewModel)
            
            VStack {
                HeaderView(selectedTab: $selectedTab)
                Spacer()
            }
            .edgesIgnoringSafeArea(.top)
        }
    }
}

