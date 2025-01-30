import SwiftUI

struct RouterView: View {
    @Binding var selectedTab: MainView.Tab
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack {
            switch selectedTab {
            case .profile:
                ProfileView()
            case .products:
                GoodsView()
                    .environmentObject(authViewModel)
            case .favorites:
                FavoriteView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
