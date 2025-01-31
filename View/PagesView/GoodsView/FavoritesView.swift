import SwiftUI

struct FavoriteProductsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: ProductViewModel

    init() {
        _viewModel = StateObject(wrappedValue: ProductViewModel(onlyFavorite: true, authViewModel: AuthViewModel()))
    }

    var body: some View {
        NavigationView {
            VStack {
                if let errorMessage = viewModel.errorMessage {
                    Text("Ошибка: (errorMessage)")
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
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.products.indices, id: \.self) { index in
                                    NavigationLink(destination: ProductView(product: $viewModel.products[index], viewModel: viewModel)) {
                                        HStack {
                                            Text(viewModel.products[index].name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                if viewModel.isLoading {
                                    ProgressView()
                                        .padding()
                                }
                            }
                            .padding()
                            .background(Color(UIColor.systemGroupedBackground))
                            .cornerRadius(12)
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
}
