import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    private let db = Firestore.firestore()
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isEditing = false
    @State private var isLoading = true
    @State private var errorMessage = ""
    
    // Поля профиля
    @State private var name = ""
    @State private var email = ""
    @State private var dateOfBirth = ""
    @State private var phoneNumber = ""
    @State private var address = ""
    @State private var bio = ""
    @State private var occupation = ""
    @State private var website = ""
    @State private var socialMedia = ""
    @State private var additionalInfo = ""
    
    var body: some View {
        VStack(alignment: .leading) { // Выравнивание по левому краю
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isLoading {
                        ProgressView("Загрузка профиля...")
                            .padding()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                if isEditing {
                                    // Поля ввода для редактирования профиля
                                    ProfileFieldEditor(title: "Имя", text: $name)
                                    ProfileFieldEditor(title: "Email", text: $email)
                                    ProfileFieldEditor(title: "Дата рождения", text: $dateOfBirth)
                                    ProfileFieldEditor(title: "Телефон", text: $phoneNumber)
                                    ProfileFieldEditor(title: "Адрес", text: $address)
                                    ProfileFieldEditor(title: "О себе", text: $bio)
                                    ProfileFieldEditor(title: "Профессия", text: $occupation)
                                    ProfileFieldEditor(title: "Веб-сайт", text: $website)
                                    ProfileFieldEditor(title: "Соцсети", text: $socialMedia)
                                    ProfileFieldEditor(title: "Дополнительно", text: $additionalInfo)
                                    
                                    Button(action: {
                                        deleteAccount()
                                    }) {
                                        Text("Удалить аккаунт")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.red)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                } else {
                                    // Информация профиля
                                    ProfileField(title: "Имя", value: name)
                                    ProfileField(title: "Email", value: email)
                                    ProfileField(title: "Дата рождения", value: dateOfBirth)
                                    ProfileField(title: "Телефон", value: phoneNumber)
                                    ProfileField(title: "Адрес", value: address)
                                    ProfileField(title: "О себе", value: bio)
                                    ProfileField(title: "Профессия", value: occupation)
                                    ProfileField(title: "Веб-сайт", value: website)
                                    ProfileField(title: "Соцсети", value: socialMedia)
                                    ProfileField(title: "Дополнительно", value: additionalInfo)
                                }
                            }
                            .padding()
                        }
                        
                        // Кнопки управления
                        HStack {
                            Button(action: {
                                if isEditing {
                                    saveProfileData()
                                }
                                isEditing.toggle()
                            }) {
                                Text(isEditing ? "Сохранить" : "Редактировать")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isEditing ? Color.green : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                authViewModel.signOut()
                            }) {
                                Text("Выйти")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }
                }
                .onAppear {
                    loadProfileData()
                }
            }
        }
    }
    
    // Загрузка данных профиля из Firestore
    private func loadProfileData() {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = "Пользователь не найден."
            isLoading = false
            return
        }
        
        db.collection("users").document(userID).getDocument { document, error in
            if let error = error {
                errorMessage = "Ошибка загрузки профиля: \(error.localizedDescription)"
            } else if let document = document, document.exists {
                let data = document.data() ?? [:]

                
                func formattedString(_ value: Any?) -> String {
                    guard let string = value as? String, !string.isEmpty else { return "-" }
                    return string
                }

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
                
            } else {
                errorMessage = "Документ профиля не найден."
            }
            isLoading = false
        }
    }

    private func saveProfileData() {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = "Пользователь не найден."
            return
        }
        
        isLoading = true // Включаем прелоадер

        let userData: [String: Any] = [
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
        
        db.collection("users").document(userID).setData(userData) { [self] error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Ошибка сохранения профиля: \(error.localizedDescription)"
                } else {
                    self.errorMessage = ""
                }
            }
        }
    }
    
    // Удаление аккаунта пользователя
    private func deleteAccount() {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = "Пользователь не найден."
            return
        }
        
        db.collection("users").document(userID).delete { error in
            if let error = error {
                errorMessage = "Ошибка удаления аккаунта: \(error.localizedDescription)"
            } else {
                Auth.auth().currentUser?.delete { error in
                    if let error = error {
                        errorMessage = "Ошибка удаления пользователя: \(error.localizedDescription)"
                    } else {
                        authViewModel.signOut()
                    }
                }
            }
        }
    }
}

struct ProfileField: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            Text(value)
                .font(.body)
        }
    }
}

struct ProfileFieldEditor: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            TextField(title, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
        }
    }
}
