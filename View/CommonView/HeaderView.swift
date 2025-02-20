import SwiftUI

struct HeaderView: View {
    @Binding var selectedTab: AppView.Tab
    
    var body: some View {
        VStack(spacing: 0) {
            safeAreaView
            tabButtons
        }
        .frame(maxWidth: .infinity)
    }
    
    private var safeAreaView: some View {
        Color(.systemGray6)
            .frame(height: UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44)
    }
    
    private var tabButtons: some View {
        HStack {
            tabButton(icon: nil, selectedTab: .profile, title: "Профиль")
            
            Spacer()
            
            tabButton(icon: nil, selectedTab: .products, title: "Товары")
            
            Spacer()
            
            tabButton(icon: nil, selectedTab: .favorites, title: "Избранное")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(Color(.systemGray6)) // Цвет фона хедера
        .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 2)
    }
    
    private func tabButton(icon: String?, selectedTab: AppView.Tab, title: String?) -> some View {
        Button(action: {
            self.selectedTab = selectedTab
        }) {
            if let icon = icon {
                Image(systemName: icon)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(self.selectedTab == selectedTab ? .blue : .gray)
                
            } else if let title = title {
                Text(title)
                    .font(.headline)
                    .foregroundColor(self.selectedTab == selectedTab ? .white : .gray)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(self.selectedTab == selectedTab ? Color.blue : Color.clear)
                    .cornerRadius(20)
            }
        }
    }
}
