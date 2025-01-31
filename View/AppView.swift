import SwiftUI

struct AppView: View {
    @State private var selectedTab: Tab = .products
    @EnvironmentObject var authViewModel: AuthViewModel
    
    enum Tab {
        case profile, products, favorites
    }
    
    var body: some View {
        ZStack {
            VStack {
                HeaderView(selectedTab: $selectedTab)
                
                renderTabView()
            }
            .edgesIgnoringSafeArea(.top)
        }
    }
    
    private func renderTabView() -> some View {
        switch selectedTab {
        case .profile:
            return AnyView(ProfileView())
            
        case .products:
            return AnyView(ProductsView()
                            .environmentObject(authViewModel))
        case .favorites:
            return AnyView(FavoriteProductsView()
                            .environmentObject(authViewModel))
        }
    }
}

