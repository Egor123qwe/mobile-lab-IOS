import SwiftUI

struct RouterView: View {
    @Binding var selectedTab: MainView.Tab
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack {
            renderTabView()
        }
    }
    
    private func renderTabView() -> some View {
        switch selectedTab {
        case .profile:
            return AnyView(ProfileView())
            
        case .products:
            return AnyView(GoodsView()
                            .environmentObject(authViewModel))
        case .favorites:
            return AnyView(FavoriteView()
                            .environmentObject(authViewModel))
        }
    }
}
