import SwiftUI

struct HeaderView: View {
    @Binding var selectedTab: MainView.Tab
    
    var body: some View {
        VStack(spacing: 0) {
            Color(.systemGray6)
                .frame(
                    height:
                        UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44
                )
            
            HStack {
                Button(action: {
                    selectedTab = .profile
                }) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(selectedTab == .profile ? .blue : .gray)
                }
                
                Spacer()
                
                // Products Button
                Button(action: {
                    selectedTab = .products
                }) {
                    Text("Товары")
                        .font(.headline)
                        .foregroundColor(selectedTab == .products ? .white : .gray)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(selectedTab == .products ? Color.blue : Color.clear)
                        .cornerRadius(20)
                }
                
                Spacer()
                
                // Favorites Button
                Button(action: {
                    selectedTab = .favorites
                }) {
                    Text("Избранное")
                        .font(.headline)
                        .foregroundColor(selectedTab == .favorites ? .white : .gray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background(selectedTab == .favorites ? Color.blue : Color.clear)
                        .cornerRadius(20)
                }
            }
            .padding(.vertical, 10).padding(.horizontal, 20)
            .background(Color(.systemGray6)) // Цвет фона хедера
            .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity) // Хедер растягивается по всей ширине
    }
}
