import FirebaseFirestore

struct Product: Identifiable, Codable {
    @DocumentID var id: String?
    
    var name: String
    var description: String
    var images: [String]
    var isFavorite: Bool? = true

    private enum CodingKeys: String, CodingKey {
        case id, name, description, images, isFavorite
    }
}
