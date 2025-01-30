import SwiftUI
import FirebaseFirestore

// MARK: - Модель товара
struct Product: Identifiable, Codable {
    @DocumentID var id: String? // Firestore ID
    var name: String
    var description: String
    var images: [String] // Ссылки на изображения
    var isFavorite: Bool? = true // Опционально с дефолтным значением

    private enum CodingKeys: String, CodingKey {
        case id, name, description, images, isFavorite
    }
}

class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var favoriteProductIds: [String] = []
    @Published var isLoading = false
    @Published var isEndReached = false
    @Published var errorMessage: String?

    private var db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot? = nil
    private let onlyFavorite: Bool
    private var authViewModel: AuthViewModel

    init(onlyFavorite: Bool = false, authViewModel: AuthViewModel) {
        self.onlyFavorite = onlyFavorite
        self.authViewModel = authViewModel
        Task {
            await loadProducts()
        }
    }

    /// Загружаем товары
    func loadProducts() async {
        guard !isLoading, !isEndReached else { return }

        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        guard let userId = authViewModel.id else { return }

        do {
            // Загружаем ID избранных товаров
            let favoriteProductIds = try await getFavoriteProductIds(for: userId)

            // Запрос товаров
            var query: Query = db.collection("products").order(by: "name").limit(to: 10)
            if let lastDoc = lastDocument {
                query = query.start(afterDocument: lastDoc)
            }

            let snapshot = try await query.getDocuments()
            var newProducts = snapshot.documents.compactMap { doc -> Product? in
                var product = try? doc.data(as: Product.self)
                if let productId = product?.id {
                    product?.isFavorite = favoriteProductIds.contains(productId)
                }
                return product
            }

            // Если включен фильтр "Только избранное" — оставляем только избранные товары
            if onlyFavorite {
                newProducts = newProducts.filter { $0.isFavorite == true }
            }

            DispatchQueue.main.async {
                self.products.append(contentsOf: newProducts)
                self.lastDocument = snapshot.documents.last
                self.isEndReached = newProducts.count < 30
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Ошибка загрузки: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    /// Получаем список ID избранных товаров пользователя
    private func getFavoriteProductIds(for userId: String) async throws -> [String] {
        let favoriteSnapshot = try await db.collection("users").document(userId).collection("favorites").getDocuments()
        return favoriteSnapshot.documents.compactMap { $0.documentID }
    }

    /// Обновление списка товаров после изменения избранного
    func reloadFavorites() async {
        DispatchQueue.main.async {
            self.products = []  // Очищаем список перед загрузкой
            self.lastDocument = nil
            self.isEndReached = false
        }
        await loadProducts()
    }
    
    /// Добавление/удаление из избранного
    func toggleFavorite(for product: Product) {
        guard let userId = authViewModel.id, let productID = product.id else { return }

        let favoriteRef = db.collection("users").document(userId).collection("favorites").document(productID)

        favoriteRef.getDocument { document, error in
            if let document = document, document.exists {
                // Удаляем из избранного
                favoriteRef.delete { error in
                    if error == nil {
                        DispatchQueue.main.async {
                            if let index = self.products.firstIndex(where: { $0.id == productID }) {
                                self.products[index].isFavorite = false
                            }
                        }
                        Task {
                            await self.reloadFavorites()
                        }
                    }
                }
            } else {
                // Добавляем в избранное
                let productData: [String: Any] = [
                    "name": product.name,
                    "description": product.description,
                    "images": product.images
                ]
                
                favoriteRef.setData(productData) { error in
                    if error == nil {
                        DispatchQueue.main.async {
                            if let index = self.products.firstIndex(where: { $0.id == productID }) {
                                self.products[index].isFavorite = true
                            }
                        }
                        Task {
                            await self.reloadFavorites()
                        }
                    }
                }
            }
        }
    }
}
// MARK: - Основной экран списка товаров
struct GoodsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // Получаем AuthViewModel из environment
    @StateObject private var viewModel: ProductViewModel

    // Конструктор для инициализации viewModel
    init() {
        _viewModel = StateObject(wrappedValue: ProductViewModel(onlyFavorite: false, authViewModel: AuthViewModel()))
    }

    var body: some View {
        NavigationView {
            VStack {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                if viewModel.isLoading && viewModel.products.isEmpty {
                    ProgressView("Загрузка...")
                        .progressViewStyle(CircularProgressViewStyle())
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
                                        Image(systemName: (product.isFavorite ?? false) ? "star.fill" : "star")
                                            .foregroundColor((product.isFavorite ?? false) ? .yellow : .gray)
                                    }
                                    .padding()
                                    .background(Color.white) // Фон элемента
                                    .cornerRadius(10) // Закругленные углы
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2) // Тень
                                }
                                .buttonStyle(PlainButtonStyle()) // Убираем стандартный стиль кнопки
                            }
                            
                            if !viewModel.isEndReached {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding()
                                        .onAppear {
                                            Task {
                                                await viewModel.loadProducts()
                                            }
                                        }
                                    Spacer()
                                }
                            }
                        }
                        .padding() // Отступы вокруг всего списка
                        .background(Color(UIColor.systemGroupedBackground)) // Фон для всего ScrollView
                        .cornerRadius(12) // Закругленные углы для ScrollView
                    }
                }
            }
        }
    }
}

// MARK: - Детальный экран товара
struct ProductDetailView: View {
    var product: Product
    @ObservedObject var viewModel: ProductViewModel
    @State private var selectedImageIndex = 0

    var body: some View {
        VStack {
            // Слайдер с изображениями
            if !product.images.isEmpty {
                // Название товара
                Text(product.name)
                    .font(.largeTitle)
                    .padding()
                
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(product.images.enumerated()), id: \.offset) { index, imageUrl in
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView() // Индикатор загрузки
                            case .success(let image):
                                image.resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 300)
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 300)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always)) // Горизонтальная карусель с индикаторами
                .frame(height: 300)
                .padding(.bottom, 10)
            }

            // Описание
            Text(product.description)
                .padding()

            // Кнопка избранного
            Button(action: {
                viewModel.toggleFavorite(for: product)
            }) {
                Text((product.isFavorite ?? false) ? "Удалить из избранного" : "Добавить в избранное")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()

            Spacer()
        }
          .padding()
    }
}
