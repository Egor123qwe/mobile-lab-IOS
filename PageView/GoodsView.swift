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
    private var authViewModel: AuthViewModel // Добавляем ссылку на AuthViewModel

    init(onlyFavorite: Bool = false, authViewModel: AuthViewModel) {
        self.onlyFavorite = onlyFavorite
        self.authViewModel = authViewModel // Инициализируем authViewModel
        Task {
            await loadProducts()
        }
    }

    // Загрузка товаров с учетом onlyFavorite
    func loadProducts() async {
        guard !isLoading, !isEndReached else { return }

        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        guard let userId = authViewModel.id else { return } // Убедимся, что есть текущий пользователь

        // Запрос товаров
        var query: Query = db.collection("products").order(by: "name").limit(to: 10)
        
        do {
            favoriteProductIds = await getFavoriteProductIds(for: userId)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Ошибка получения избранных товаров \(error.localizedDescription)"
                
                self.isLoading = false
            }
            
            return
        }
        
        
        

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        do {
            let snapshot = try await query.getDocuments()

            // Получаем список всех товаров
            let newProducts = snapshot.documents.compactMap { doc -> Product? in
                try? doc.data(as: Product.self)
            }

            // Используем TaskGroup для параллельной загрузки информации о "избранности" товаров
            var updatedProducts: [Product] = []
            try await withThrowingTaskGroup(of: Product.self) { group in
                for product in newProducts {
                    if let productId = product.id, !self.favoriteProductIds.contains(productId) && self.onlyFavorite {
                        continue
                    }
                    
                    group.addTask {
                        guard let productId = product.id else { return product }

                        var updatedProduct = product
                        var isFavorite = self.favoriteProductIds.contains(productId)
                        
                        updatedProduct.isFavorite = isFavorite
                        
                        return updatedProduct
                    }
                }

                for try await updatedProduct in group {
                    updatedProducts.append(updatedProduct)
                }
            }

            // Обновление списка товаров
            DispatchQueue.main.async {
                self.products.append(contentsOf: updatedProducts)
                self.lastDocument = snapshot.documents.last
                self.isEndReached = updatedProducts.count < 10
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Ошибка загрузки: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    // Функция для получения ID избранных товаров
    private func getFavoriteProductIds(for userId: String) async -> [String] {
        do {
            let favoriteSnapshot = try await db.collection("users").document(userId).collection("favorites").getDocuments()
            let favoriteIds = favoriteSnapshot.documents.compactMap { $0.documentID } // Получаем ID товаров в избранном
            
            return favoriteIds
        } catch {
            print("Ошибка получения избранных товаров: \(error.localizedDescription)")
            return []
        }
    }
    
    // Обновление состояния избранного товара
    func toggleFavorite(for product: Product) {
        guard let userId = authViewModel.id, let productID = product.id else { return }

        // Ссылка на документ пользователя и подколлекцию "favorites"
        let favoriteRef = db.collection("users").document(userId).collection("favorites").document(productID)
        
        // Проверяем, есть ли уже товар в избранном
        favoriteRef.getDocument { document, error in
            if let document = document, document.exists {
                // Если товар уже в избранном — удаляем
                favoriteRef.delete() { error in
                    if let error = error {
                        self.errorMessage = "Ошибка удаления из избранного: \(error.localizedDescription)"
                    } else {
                        // Обновляем список товаров, чтобы отобразить изменения
                        if let index = self.products.firstIndex(where: { $0.id == productID }) {
                            self.products[index].isFavorite = false
                        }
                        print("Товар удален из избранного для пользователя \(userId)")
                    }
                }
            } else {
                // Если товара нет в избранном — добавляем
                let productData: [String: Any] = [
                    "name": product.name,
                    "description": product.description,
                    "images": product.images
                ]
                
                favoriteRef.setData(productData) { error in
                    if let error = error {
                        self.errorMessage = "Ошибка добавления в избранное: \(error.localizedDescription)"
                    } else {
                        // Обновляем список товаров, чтобы отобразить изменения
                        if let index = self.products.firstIndex(where: { $0.id == productID }) {
                            self.products[index].isFavorite = true
                        }
                        print("Товар добавлен в избранное для пользователя \(userId)")
                    }
                }
            }
        }
    }

    
    func reloadFavorites() async {
        self.products = [] // Очищаем список перед загрузкой
        self.lastDocument = nil // Сбрасываем пагинацию
        self.isEndReached = false
        await loadProducts()
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
                    List {
                        ForEach(viewModel.products) { product in
                            NavigationLink(destination: ProductDetailView(product: product, viewModel: viewModel)) {
                                HStack {
                                    Text(product.name)
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: (product.isFavorite ?? false) ? "star.fill" : "star")
                                        .foregroundColor((product.isFavorite ?? false) ? .yellow : .gray)
                                }
                            }
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
