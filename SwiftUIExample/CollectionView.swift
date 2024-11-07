import SwiftUI
import Buy // Ensure the correct module is imported
import SDWebImageSwiftUI // Import SDWebImage

// Simple image cache
class ImageCache {
    static let shared = NSCache<NSURL, UIImage>()
}

struct CollectionView: View {
    @StateObject private var cartManager = CartManager.shared
    @State private var collections: [Storefront.Collection] = []
    @State private var selectedProduct: Storefront.Product?
    @State private var checkoutURL: URL?
    @State private var isLoading: Bool = false // Add loading state

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView("Loading Collections...") // Show loading indicator
                        .padding()
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(collections, id: \.id) { collection in
                            NavigationLink(destination: ProductListView(collection: collection, selectedProduct: $selectedProduct, checkoutURL: $checkoutURL)) {
                                CollectionItemView(collection: collection)
                            }
                        }
                    }
                    .padding()
                }
            }
            .onAppear {
                fetchCollections()
            }
            .navigationTitle("Collections")
        }
    }

    private func fetchCollections() {
        isLoading = true // Set loading state to true
        cartManager.fetchCollections { fetchedCollections in
            DispatchQueue.main.async {
                if let fetchedCollections = fetchedCollections {
                    self.collections = fetchedCollections
                } else {
                    print("Failed to fetch collections.")
                }
                isLoading = false // Reset loading state
            }
        }
    }
}


struct CollectionItemView: View {
    let collection: Storefront.Collection

    var body: some View {
        VStack {
            if let firstProduct = collection.products.edges.first?.node,
               let imageURL = firstProduct.images.edges.first?.node.url {
                // Use WebImage from SDWebImage for caching
                WebImage(url: imageURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill) // Maintain aspect ratio while filling
                    .frame(width: 150, height: 150) // Fixed dimensions for symmetrical appearance
                    .clipped() // Ensure the image stays within the bounds
                    .cornerRadius(10) // Round corners for symmetry
            } else {
                placeholderImageView(withImage: "appLogo") // Placeholder image
            }

            Text(collection.title ?? "No Title")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(.wrapsodyGold))
                .padding(.top, 5)
        }
        .frame(width: 150, height: 200) // Fixed width and height for symmetry
        .padding(8) // Add padding around the entire item for symmetry
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(radius: 5)
    }

    @ViewBuilder
    private func placeholderImageView(withText text: String = "Image not available", withImage imageName: String? = nil) -> some View {
        if let imageName = imageName {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill) // Maintain aspect ratio while filling
                .frame(width: 150, height: 150) // Fixed dimensions for symmetrical appearance
                .cornerRadius(10)
        } else {
            Color.gray
                .frame(width: 150, height: 150) // Fixed dimensions for symmetrical appearance
                .cornerRadius(10)
                .overlay(Text(text).foregroundColor(.white))
        }
    }
}




// Custom AsyncImage implementation with caching
struct CachedAsyncImage: View {
    let url: URL
    
    @State private var image: UIImage?
    @State private var isLoading: Bool = true

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(10)
            } else if isLoading {
                placeholderImageView(withText: "Loading...")
            } else {
                placeholderImageView(withText: "Image not available")
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        let cacheKey = NSURL(string: url.absoluteString)!

        // Check if the image is cached
        if let cachedImage = ImageCache.shared.object(forKey: cacheKey) {
            self.image = cachedImage
            self.isLoading = false
        } else {
            // If not cached, download the image
            isLoading = true
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let downloadedImage = UIImage(data: data) {
                    // Cache the downloaded image
                    ImageCache.shared.setObject(downloadedImage, forKey: cacheKey)
                    DispatchQueue.main.async {
                        self.image = downloadedImage
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            }.resume()
        }
    }

    @ViewBuilder
    private func placeholderImageView(withText text: String) -> some View {
        Color.gray
            .frame(height: 120)
            .cornerRadius(10)
            .overlay(Text(text).foregroundColor(.white))
    }
}

struct ProductListView: View {
    let collection: Storefront.Collection
    @Binding var selectedProduct: Storefront.Product?
    @Binding var checkoutURL: URL?
    @State private var cart: Storefront.Cart? = CartManager.shared.cart
    @State private var displayedProducts: [Storefront.Product] = []
    @State private var isLoading: Bool = false // Loading state
    @State private var endCursor: String?
    @State private var searchText: String = ""

    var filteredProducts: [Storefront.Product] {
        if searchText.isEmpty {
            return displayedProducts
        } else {
            return displayedProducts.filter { product in
                let titleMatches = product.title.localizedCaseInsensitiveContains(searchText)
                let vendorMatches = product.vendor.localizedCaseInsensitiveContains(searchText)
              let descriptionMatches = product.description.localizedCaseInsensitiveContains(searchText) ?? false
                let tagsMatch = product.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) ?? false
                let productTypeMatches = product.productType.localizedCaseInsensitiveContains(searchText) ?? false

                return titleMatches || vendorMatches || descriptionMatches || tagsMatch || productTypeMatches
            }
        }
    }

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $searchText)
                .padding()

            ScrollView {
                if isLoading { // Check if loading
                    ProgressView("Loading Products...") // Show loading indicator
                        .padding()
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredProducts, id: \.id) { product in
                            NavigationLink(destination: CatalogView(cartManager: CartManager.shared, checkoutURL: $checkoutURL, product: product)) {
                                ProductRowView(product: product)
                            }
                            .onAppear {
                                if let lastProduct = filteredProducts.last, product.id == lastProduct.id {
                                    loadMoreProducts()
                                }
                            }
                        }

                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .navigationTitle(collection.title ?? "Products")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadProducts()
        }
    }

    private func loadProducts() {
        guard !isLoading else { return }
        isLoading = true // Set loading state

        CartManager.shared.fetchProducts(for: collection, after: endCursor, itemsPerPage: 250) { products, cursor in
            DispatchQueue.main.async {
                if let products = products {
                    let existingIDs = Set(displayedProducts.map { $0.id })
                    let uniqueProducts = products.filter { !existingIDs.contains($0.id) }
                    displayedProducts.append(contentsOf: uniqueProducts)
                    endCursor = cursor
                }
                isLoading = false // Reset loading state
            }
        }
    }

    private func loadMoreProducts() {
        guard !isLoading && endCursor != nil else { return }
        loadProducts()
    }
}





struct ProductRowView: View {
    let product: Storefront.Product
    @State private var isFavorited: Bool = false // State to manage favoriting

    private var price: String {
        if let firstVariant = product.variants.nodes.first {
            let amount = firstVariant.price.amount
            // Convert the Decimal to Double for formatting
            let doubleAmount = NSDecimalNumber(decimal: amount).doubleValue
            // Format the amount with a dollar symbol and two decimal places
            return String(format: "$%.2f", doubleAmount)
        }
        return "Price Unavailable"
    }

    // Unique identifier for the product
  private var productId: String {
      return product.id.rawValue // Use rawValue to get the string representation
  }


    // Load favorite status from UserDefaults
    private func loadFavoriteStatus() {
        let favorites = UserDefaults.standard.array(forKey: "favoriteProducts") as? [String] ?? []
        isFavorited = favorites.contains(productId)
    }

    // Save favorite status to UserDefaults
    private func toggleFavorite() {
        var favorites = UserDefaults.standard.array(forKey: "favoriteProducts") as? [String] ?? []

        if isFavorited {
            // Remove from favorites
            favorites.removeAll { $0 == productId }
        } else {
            // Add to favorites
            favorites.append(productId)
        }
        
        UserDefaults.standard.set(favorites, forKey: "favoriteProducts")
        isFavorited.toggle()
    }

    var body: some View {
        VStack {
            // Heart icon at the top right corner
            HStack {
                Spacer() // Pushes the heart button to the right
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .resizable()
                        .foregroundColor(isFavorited ? .red : .gray)
                        .frame(width: 24, height: 24)
                }
                .padding(.trailing, 2) // Add spacing on the right side of the button
            }
            .padding(.top, 2) // Add padding to the top of the HStack

            // Display the product image
            if let imageUrl = product.featuredImage?.url {
                WebImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit) // Maintain aspect ratio while fitting
                        .frame(maxWidth: .infinity) // Ensure the image takes up full width
                        .frame(height: 120) // Set a consistent height for the image
                        .clipped() // Clip excess parts of the image
                } placeholder: {
                    Rectangle()
                        .foregroundColor(.gray)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .wrapsodyGold))
                        )
                        .frame(height: 120) // Set height for placeholder
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
            } else {
                Rectangle()
                    .foregroundColor(.gray)
                    .overlay(Text("No Image Available").foregroundColor(.white))
                    .frame(height: 120) // Set height for "no image" placeholder
            }

            // Display the product title
            Text(product.title ?? "Unknown Product")
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
                .padding(.top, 5)

            // Display the price
            Text(price)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 2)

            Spacer() // Fill remaining space to ensure uniform height
        }
        .padding(16) // Add padding around the row
        .frame(height: 300) // Set a fixed height for the entire row
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .frame(maxWidth: .infinity) // Ensure the row takes up full width
        .onAppear(perform: loadFavoriteStatus) // Load favorite status when the view appears
    }
}



struct CollectionView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionView()
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            TextField("Search By Name or Brand", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        if !text.isEmpty {
                            Button(action: {
                                text = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 8)
                        }
                    }
                )
                .padding(.horizontal, 10)
        }
    }
}


extension CartManager {
    // Fetch products with pagination using the cursor for a specific collection
    func fetchProducts(for collection: Storefront.Collection, after cursor: String? = nil, itemsPerPage: Int = 250, onCompletionHandler: @escaping ([Storefront.Product]?, String?) -> Void) {
        // Adjust the query to filter products by collection ID
        let query = Storefront.buildQuery(inContext: Storefront.InContextDirective(country: Storefront.CountryCode.inferRegion())) { $0
            .collection(id: collection.id) { collection in // Use collection ID to fetch products
                collection.products(first: Int32(itemsPerPage), after: cursor) { $0
                    .edges { edge in
                        edge.node { $0.productFragment() }
                        edge.cursor() // Fetch cursor for the next page
                    }
                    .pageInfo { $0
                        .hasNextPage()
                        .endCursor() // Get the cursor for the next page
                    }
                }
            }
        }

        client.execute(query: query) { result in
            switch result {
            case .success(let query):
                let products = query.collection?.products.edges.map { $0.node }
                let endCursor = query.collection?.products.pageInfo.endCursor
                onCompletionHandler(products, endCursor)
            case .failure(let error):
                print("Failed to fetch products: \(error)")
                onCompletionHandler(nil, nil)
            }
        }
    }
}
