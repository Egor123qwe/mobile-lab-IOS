import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var isEditing = false
    @State private var isLoading = true
    @State private var errorMessage = ""
    
    private let db = Firestore.firestore()
    
    @State private var profileData = ProfileModel()

    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isLoading {
                        ProgressView("Загрузка профиля...")
                            .padding()
                    } else {
                        profileContent
                    }
                    
                    if !errorMessage.isEmpty {
                        errorMessageView
                    }
                }
                .onAppear {
                    loadProfileData()
                }
            }
        }
    }
    
    private var profileContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isEditing {
                ProfileFieldEditor(title: "Имя", text: $profileData.name)
                ProfileFieldEditor(title: "Email", text: $profileData.email)
                ProfileFieldEditor(title: "Дата рождения", text: $profileData.dateOfBirth)
                ProfileFieldEditor(title: "Телефон", text: $profileData.phoneNumber)
                ProfileFieldEditor(title: "Адрес", text: $profileData.address)
                ProfileFieldEditor(title: "О себе", text: $profileData.bio)
                ProfileFieldEditor(title: "Профессия", text: $profileData.occupation)
                ProfileFieldEditor(title: "Веб-сайт", text: $profileData.website)
                ProfileFieldEditor(title: "Соцсети", text: $profileData.socialMedia)
                ProfileFieldEditor(title: "Дополнительно", text: $profileData.additionalInfo)
                
                deleteAccountButton
            } else {
                ProfileField(title: "Имя", value: profileData.name)
                ProfileField(title: "Email", value: profileData.email)
                ProfileField(title: "Дата рождения", value: profileData.dateOfBirth)
                ProfileField(title: "Телефон", value: profileData.phoneNumber)
                ProfileField(title: "Адрес", value: profileData.address)
                ProfileField(title: "О себе", value: profileData.bio)
                ProfileField(title: "Профессия", value: profileData.occupation)
                ProfileField(title: "Веб-сайт", value: profileData.website)
                ProfileField(title: "Соцсети", value: profileData.socialMedia)
                ProfileField(title: "Дополнительно", value: profileData.additionalInfo)
            }

            buttonsView
        }
        .padding()
    }
    
    private var errorMessageView: some View {
        Text(errorMessage)
            .foregroundColor(.red)
            .font(.caption)
            .padding()
    }

    private var deleteAccountButton: some View {
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
    }

    private var buttonsView: some View {
        HStack {
            editSaveButton
            signOutButton
        }
        .padding()
    }
    
    private var editSaveButton: some View {
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
    }

    private var signOutButton: some View {
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
                self.profileData = ProfileModel(from: data)
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
        
        isLoading = true

        db.collection("users").document(userID).setData(profileData.toDictionary()) { error in
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
