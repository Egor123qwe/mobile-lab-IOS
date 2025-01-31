import FirebaseFirestore
import Combine

class ProductViewModel: ObservableObject {
    @Published var products: [ProductModel] = []
    @Published var filteredProducts: [ProductModel] = []
    @Published var favoriteProductIds: [String] = []
    @Published var isLoading = false
    @Published var isEndReached = false
    @Published var errorMessage: String?

    private var db = Firestore.firestore()
    
    private var lastDocument: DocumentSnapshot? = nil
    private let onlyFavorite: Bool
    private var authViewModel: AuthViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(onlyFavorite: Bool = false, authViewModel: AuthViewModel) {
        self.onlyFavorite = onlyFavorite
        self.authViewModel = authViewModel
        Task {
            await loadProducts()
        }
    }

    func loadProducts() async {
        guard !isLoading, !isEndReached else { return }

        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        guard let userId = authViewModel.id else {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }

        // Попытка загрузить данные из кэша, если они есть
        if self.products.isEmpty {
            loadFromCache()
        }

        // Загружаем данные с Firestore
        do {
            let favoriteProductIds = try await getFavoriteProductIds(for: userId)

            var query: Query = db.collection("products").order(by: "name").limit(to: 20)
            if let lastDoc = lastDocument {
                query = query.start(afterDocument: lastDoc)
            }

            let snapshot = try await query.getDocuments()
            var newProducts = snapshot.documents.compactMap { doc -> ProductModel? in
                var product = try? doc.data(as: ProductModel.self)
                if let productId = product?.id {
                    product?.isFavorite = favoriteProductIds.contains(productId)
                }
                return product
            }

            if onlyFavorite {
                newProducts = newProducts.filter { $0.isFavorite == true }
            }

            DispatchQueue.main.async {
                self.products.append(contentsOf: newProducts)
                self.filteredProducts = self.products
                self.lastDocument = snapshot.documents.last
                self.isEndReached = newProducts.count < 20
                self.isLoading = false
                
                print("Загруженные продукты: \(self.products.count)")  // Логирование
            }

            // Кэшируем данные
            saveToCache(products: self.products)
            print("Сохранены данные в кэш: \(self.products.count) продуктов")

        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Ошибка загрузки: \(error.localizedDescription)"
                self.isLoading = false
            }

            // Если произошла ошибка загрузки, пытаемся восстановить из кэша
            loadFromCache()
        }
    }

    private func getFavoriteProductIds(for userId: String) async throws -> [String] {
        let favoriteSnapshot = try await db.collection("users").document(userId).collection("favorites").getDocuments()
        return favoriteSnapshot.documents.compactMap { $0.documentID }
    }

    func reloadFavorites() async {
        DispatchQueue.main.async {
            self.products = []
            self.filteredProducts = []
            self.lastDocument = nil
            self.isEndReached = false
        }
        await loadProducts()
    }
    
    func toggleFavorite(for product: ProductModel) {
        guard let userId = authViewModel.id, let productID = product.id else { return }

        let favoriteRef = db.collection("users").document(userId).collection("favorites").document(productID)

        favoriteRef.getDocument { document, error in
            if let document = document, document.exists {
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

    // Функция для поиска продуктов по имени
    func searchProducts(query: String) {
        if query.isEmpty {
            filteredProducts = products
        } else {
            filteredProducts = products.filter { $0.name.lowercased().contains(query.lowercased()) }
        }
    }
    
    private func saveToCache(products: [ProductModel]) {
        print("Сохранение данных в кэш, текущий массив продуктов: \(products)")

        let encoder = JSONEncoder()

        if let encoded = try? encoder.encode(products) {
            let fileManager = FileManager.default
            if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentDirectory.appendingPathComponent("cachedProducts.json")

                do {
                    try encoded.write(to: fileURL)
                    print("Продукты сохранены в файл: \(fileURL.path)")
                } catch {
                    print("Ошибка при сохранении данных в файл: \(error)")
                }
            }
        } else {
            print("Ошибка при сериализации продуктов")
        }
    }

    private func loadFromCache() {
        let fileManager = FileManager.default
        if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentDirectory.appendingPathComponent("cachedProducts.json")
            
            if let data = try? Data(contentsOf: fileURL) {
                let decoder = JSONDecoder()
                do {
                    let decodedProducts = try decoder.decode([ProductModel].self, from: data)
                    DispatchQueue.main.async {
                        if !decodedProducts.isEmpty {
                            self.products = decodedProducts
                            self.filteredProducts = self.products
                            print("Загружены данные из файла: \(self.products.count) продуктов")
                        }
                    }
                } catch {
                    print("Ошибка при десериализации данных из файла: \(error.localizedDescription)")
                }
            } else {
                print("Нет данных в кэше (файл не найден)")
            }
        }
    }
}
