import SwiftUI

struct RouterView: View {
    @Binding var selectedTab: MainView.Tab
    
    var body: some View {
        VStack {
            switch selectedTab {
            case .profile:
                ProfileView()
            case .products:
                GoodsView()
            case .favorites:
                FavoriteView()
            }
        }
    }
}


