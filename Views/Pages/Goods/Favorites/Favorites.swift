import SwiftUI

struct FavoriteView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // Получаем AuthViewModel из environment
    @StateObject private var viewModel: ProductViewModel

    // Конструктор для инициализации viewModel
    init() {
        _viewModel = StateObject(wrappedValue: ProductViewModel(onlyFavorite: true, authViewModel: AuthViewModel()))
    }

    var body: some View {
        VStack {
            if let errorMessage = viewModel.errorMessage {
                Text("Ошибка: (errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }

            if viewModel.isLoading && viewModel.products.isEmpty {
                ProgressView("Загрузка...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                if viewModel.products.isEmpty {
                    Text("Объекты не найдены")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) { // Увеличьте расстояние между элементами
                            ForEach(viewModel.products) { product in
                                NavigationLink(destination: ProductDetailView(product: product, viewModel: viewModel)) {
                                    HStack {
                                        Text(product.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.white) // Фон элемента
                                    .cornerRadius(10) // Закругленные углы
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2) // Тень
                                }
                                .buttonStyle(PlainButtonStyle()) // Убираем стандартный стиль кнопки
                            }
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .padding() // Отступы вокруг всего ScrollView
                        .background(Color(UIColor.systemGroupedBackground)) // Фон для всего ScrollView
                        .cornerRadius(12) // Закругленные углы для ScrollView
                    }
                    .onAppear {
                        Task {
                            await viewModel.loadProducts()
                        }
                    }
                }
            }
        }
        .padding() // Отступы вокруг всего VStack
    }
}
