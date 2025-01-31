import FirebaseFirestore

struct ReviewModel: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var userName: String
    var rating: Int
    var comment: String
    var timestamp: Timestamp
}
