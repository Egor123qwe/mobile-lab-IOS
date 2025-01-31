import SwiftUI

struct ProductsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: ProductViewModel
    @State private var searchText = ""

    init() {
        _viewModel = StateObject(
            wrappedValue: ProductViewModel(onlyFavorite: false, authViewModel: AuthViewModel())
        )
    }

    var body: some View {
        NavigationView {
            VStack {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                if viewModel.isLoading && viewModel.products.isEmpty {
                    ProgressView("Загрузка...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else {
                    VStack {
                        // Поисковое поле
                        TextField("Фильтрация и поиск по названию", text: $searchText)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: searchText) { _ in
                                viewModel.searchProducts(query: searchText)
                            }

                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.filteredProducts.indices, id: \.self) { index in
                                    NavigationLink(destination: ProductView(product: $viewModel.products[index], viewModel: viewModel)) {
                                        HStack {
                                            Text(viewModel.filteredProducts[index].name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: (viewModel.filteredProducts[index].isFavorite ?? false) ? "star.fill" : "star")
                                                .foregroundColor((viewModel.filteredProducts[index].isFavorite ?? false) ? .yellow : .gray)
                                        }
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }

                                if !viewModel.isEndReached {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .padding()
                                            .onAppear {
                                                Task {
                                                    await viewModel.loadProducts()
                                                }
                                            }
                                        Spacer()
                                    }
                                }
                            }
                            .padding()
                            .background(Color(UIColor.systemGroupedBackground))
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
    }
}
