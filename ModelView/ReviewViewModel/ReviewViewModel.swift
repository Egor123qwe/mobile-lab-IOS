import FirebaseFirestore
import FirebaseAuth

@MainActor
class ReviewViewModel: ObservableObject {
    @Published var reviews: [ReviewModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    private var authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    /// Загружает отзывы для конкретного товара
    func loadReviews(for productId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let snapshot = try await db.collection("products").document(productId).collection("reviews")
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            reviews = snapshot.documents.compactMap { try? $0.data(as: ReviewModel.self) }
        } catch {
            errorMessage = "Ошибка загрузки: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Добавляет новый отзыв для товара
    func addReview(to productId: String, rating: Int, comment: String) async {
        guard let userId = authViewModel.id else {
            errorMessage = "Ошибка: пользователь не найден"
            return
        }
        
        let userName = await fetchUserName(by: userId) ?? "Аноним"

        let reviewData: [String: Any] = [
            "userId": userId,
            "userName": userName,
            "rating": rating,
            "comment": comment,
            "timestamp": Timestamp()
        ]
        
        do {
            let reviewRef = db.collection("products").document(productId).collection("reviews").document()
            try await reviewRef.setData(reviewData)
            await loadReviews(for: productId)
        } catch {
            errorMessage = "Ошибка добавления: \(error.localizedDescription)"
        }
    }
    
    /// Получает имя пользователя по его ID
    func fetchUserName(by userId: String) async -> String? {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            return document.data()?["name"] as? String
        } catch {
            print("Ошибка загрузки имени пользователя: \(error.localizedDescription)")
            return nil
        }
    }
}
