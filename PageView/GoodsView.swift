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
    @Published var isLoading = false
    @Published var isEndReached = false
    @Published var errorMessage: String?

    private var db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot? = nil
    private let onlyFavorite: Bool

    init(onlyFavorite: Bool = false) {
        self.onlyFavorite = onlyFavorite
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

        var query: Query = db.collection("products").order(by: "name").limit(to: 10)

        if onlyFavorite {
            query = query.whereField("isFavorite", isEqualTo: true)
        }

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        do {
            let snapshot = try await query.getDocuments()

            let newProducts = snapshot.documents.compactMap { doc -> Product? in
                try? doc.data(as: Product.self)
            }

            DispatchQueue.main.async {
                self.products.append(contentsOf: newProducts)
                self.lastDocument = snapshot.documents.last
                self.isEndReached = newProducts.count < 10
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Ошибка загрузки: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    // Обновление состояния избранного товара
    func toggleFavorite(for product: Product) {
        guard let index = products.firstIndex(where: { $0.id == product.id }),
              let productID = product.id else { return }

        var updatedProduct = products[index]
        updatedProduct.isFavorite = !(updatedProduct.isFavorite ?? false)
        products[index] = updatedProduct

        let productRef = db.collection("products").document(productID)

        productRef.updateData(["isFavorite": updatedProduct.isFavorite ?? false]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Ошибка обновления: \(error.localizedDescription)"
                    self.products[index] = product // Откат при ошибке
                    return
                }
                
                // Если на странице избранного — обновляем весь список, а не удаляем вручную
                if self.onlyFavorite {
                    Task {
                        await self.reloadFavorites()
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
    @StateObject private var viewModel = ProductViewModel()

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
