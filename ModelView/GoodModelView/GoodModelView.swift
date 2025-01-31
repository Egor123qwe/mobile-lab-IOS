import FirebaseFirestore

class ProductViewModel: ObservableObject {
    @Published var products: [ProductModel] = []
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

    func loadProducts() async {
        guard !isLoading, !isEndReached else { return }

        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        guard let userId = authViewModel.id else { return }

        do {
            let favoriteProductIds = try await getFavoriteProductIds(for: userId)

            var query: Query = db.collection("products").order(by: "name").limit(to: 30)
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

    private func getFavoriteProductIds(for userId: String) async throws -> [String] {
        let favoriteSnapshot = try await db.collection("users").document(userId).collection("favorites").getDocuments()
        return favoriteSnapshot.documents.compactMap { $0.documentID }
    }

    func reloadFavorites() async {
        DispatchQueue.main.async {
            self.products = []
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
}
