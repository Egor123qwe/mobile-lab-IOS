struct ProfileModel {
    var name: String = ""
    var email: String = ""
    var dateOfBirth: String = ""
    var phoneNumber: String = ""
    var address: String = ""
    var bio: String = ""
    var occupation: String = ""
    var website: String = ""
    var socialMedia: String = ""
    var additionalInfo: String = ""
    
    // Инициализатор по умолчанию
    init(from data: [String: Any] = [:]) {
        self.name = formattedString(data["name"])
        self.email = formattedString(data["email"])
        self.dateOfBirth = formattedString(data["dateOfBirth"])
        self.phoneNumber = formattedString(data["phoneNumber"])
        self.address = formattedString(data["address"])
        self.bio = formattedString(data["bio"])
        self.occupation = formattedString(data["occupation"])
        self.website = formattedString(data["website"])
        self.socialMedia = formattedString(data["socialMedia"])
        self.additionalInfo = formattedString(data["additionalInfo"])
    }

    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "email": email,
            "dateOfBirth": dateOfBirth,
            "phoneNumber": phoneNumber,
            "address": address,
            "bio": bio,
            "occupation": occupation,
            "website": website,
            "socialMedia": socialMedia,
            "additionalInfo": additionalInfo
        ]
    }
    
    private func formattedString(_ value: Any?) -> String {
        guard let string = value as? String, !string.isEmpty else { return "-" }
        return string
    }
}
