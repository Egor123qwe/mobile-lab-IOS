import SwiftUI
import FirebaseFirestore

struct ProductView: View {
    @Binding var product: ProductModel
    @ObservedObject var viewModel: ProductViewModel
    @State private var selectedImageIndex = 0
    @StateObject private var reviewViewModel = ReviewViewModel(authViewModel: AuthViewModel())
    @State private var newReviewText = ""
    @State private var newRating = 5

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if !product.images.isEmpty {
                    TabView(selection: $selectedImageIndex) {
                        ForEach(Array(product.images.enumerated()), id: \.offset) { index, imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image.resizable()
                                        .scaledToFit()
                                        .frame(height: 300)
                                        .cornerRadius(12)
                                        .shadow(radius: 5)
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 300)
                                        .foregroundColor(.gray)
                                        .cornerRadius(12)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .frame(height: 300)
                    .padding()
                }

                Text(product.name)
                    .font(.title)
                    .bold()
                    .padding(.horizontal)
                
                Text(product.description)
                    .font(.body)
                    .padding(.horizontal)
                    .padding(.bottom)

                Button(action: {
                    viewModel.toggleFavorite(for: product)
                }) {
                    HStack {
                        Image(systemName: product.isFavorite ?? false ? "heart.fill" : "heart")
                            .foregroundColor(.white)
                        Text(product.isFavorite ?? false ? "Удалить из избранного" : "Добавить в избранное")
                            .bold()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Divider()
                    .padding(.vertical)
                
                Text("Отзывы")
                    .font(.headline)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(reviewViewModel.reviews) { review in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(review.userName)
                                    .font(.subheadline)
                                    .bold()
                                Spacer()
                                Text(String(repeating: "★", count: review.rating))
                                    .foregroundColor(.yellow)
                            }
                            Text(review.comment)
                                .font(.body)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .onAppear {
                    Task {
                        await reviewViewModel.loadReviews(for: product.id ?? "")
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Оставьте свой отзыв")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack {
                        TextField("Введите отзыв", text: $newReviewText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(height: 44)
                            .padding(.horizontal)
                    }
                    
                    HStack {
                        Text("Оценка:")
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= newRating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    newRating = star
                                }
                        }
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            Task {
                                await reviewViewModel.addReview(to: product.id ?? "", rating: newRating, comment: newReviewText)
                                newReviewText = ""
                                newRating = 5
                            }
                        }) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Отправить")
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        Spacer()
                    }
                    .padding(.top)
                }
                .padding(.vertical)
            }
        }
    }
}
