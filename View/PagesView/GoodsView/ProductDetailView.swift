import SwiftUI

struct ProductView: View {
    @Binding var product: ProductModel
    @ObservedObject var viewModel: ProductViewModel
    @State private var selectedImageIndex = 0

    var body: some View {
        VStack {
            if !product.images.isEmpty {
                Text(product.name)
                    .font(.largeTitle)
                    .padding()
                
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(product.images.enumerated()), id: \.offset) { index, imageUrl in
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                
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
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .frame(height: 300)
                .padding(.bottom, 10)
            }

            Text(product.description)
                .padding()

            Button(action: {
                viewModel.toggleFavorite(for: product)
            }) {
                Text(product.isFavorite ?? false ? "Удалить из избранного" : "Добавить в избранное")
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
