import SwiftUI

struct FavoriteView: View {
    @StateObject private var viewModel = ProductViewModel(onlyFavorite: true)

    var body: some View {
        VStack {
            if let errorMessage = viewModel.errorMessage {
                Text("Ошибка: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }

            if viewModel.isLoading && viewModel.products.isEmpty {
                ProgressView("Загрузка...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                if viewModel.products.isEmpty {
                    Text("Объекты не найдены")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.products) { product in
                            NavigationLink(destination: ProductDetailView(product: product, viewModel: viewModel)) {
                                HStack {
                                    Text(product.name)
                                        .font(.headline)
                                    Spacer()
                                }
                            }
                        }
                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        }
                    }
                    .onAppear {
                        Task {
                            await viewModel.loadProducts()
                        }
                    }
                }
            }
        }
    }
}
