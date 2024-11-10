import SwiftUI

// MARK: - LineItem Model
struct LineItem: Identifiable {
    let id: String
    let title: String
    let quantity: Int
    let price: String
    let imageUrl: String? // Add imageUrl property for the image URL
}

// MARK: - Order Model
struct Order: Identifiable {
    let id: UUID
    let date: Date
    let orderId: String
    let orderName: String
    let totalAmount: String
    let subtotalAmount: String // Subtotal amount field
    let totalShippingAmount: String // Shipping amount field
    let fulfillmentStatus: String
    let lineItems: [LineItem]
}

class CacheManager {
    static let shared = CacheManager()

    private var imageCache = NSCache<NSString, UIImage>()

    private init() {}

    func getCachedImage(for url: URL) -> UIImage? {
        return imageCache.object(forKey: url.absoluteString as NSString)
    }

    func cacheImage(_ image: UIImage, for url: URL) {
        imageCache.setObject(image, forKey: url.absoluteString as NSString)
    }
}

// MARK: - OrderViewModel
class OrderViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isLoading: Bool = true  // Track loading state

    init() {
        fetchOrders()
    }

    func fetchOrders() {
        guard let customerAccessToken = UserDefaults.standard.string(forKey: "customerAccessToken") else {
            print("Customer access token not found.")
            self.isLoading = false
            return
        }

        CartManager.shared.fetchPastOrders(customerAccessToken: customerAccessToken) { [weak self] fetchedOrders in
            guard let self = self else { return }

            // Set loading to false once data is fetched or on error
            self.isLoading = false

            if let fetchedOrders = fetchedOrders {
                self.orders = fetchedOrders.map { order in
                    let lineItems = order.lineItems.edges.compactMap { edge in
                        let node = edge.node
                        return LineItem(
                            id: node.variant?.id.rawValue ?? "Unknown ID",
                            title: node.title,
                            quantity: Int(node.quantity) ?? 0,
                            price: "$\(node.variant?.price.amount ?? Decimal(0)) \(node.variant?.price.currencyCode.rawValue ?? "USD")",
                            imageUrl: node.variant?.image?.url.absoluteString
                        )
                    }

                    return Order(
                        id: UUID(),
                        date: order.processedAt,
                        orderId: order.id.rawValue,
                        orderName: order.name ?? "Unknown Order Number",
                        totalAmount: "$\(order.totalPrice.amount) \(order.totalPrice.currencyCode.rawValue ?? "USD")",
                        subtotalAmount: "$\(order.subtotalPrice?.amount ?? Decimal(0)) \(order.subtotalPrice?.currencyCode.rawValue ?? "USD")",
                        totalShippingAmount: "$\(order.totalShippingPrice.amount) \(order.totalShippingPrice.currencyCode.rawValue ?? "USD")",
                        fulfillmentStatus: order.fulfillmentStatus.rawValue ?? "Unknown Status",
                        lineItems: lineItems
                    )
                }
                self.orders.sort { $0.date > $1.date }
            } else {
                print("No orders found or error fetching orders.")
            }
        }
    }
}


struct OrderHistoryView: View {
    @StateObject private var viewModel = OrderViewModel()

    var body: some View {
        VStack {
            if viewModel.isLoading {
                // Show loading indicator while data is being fetched
                ProgressView("Loading Orders...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .padding()
            } else if viewModel.orders.isEmpty {
                // Show message if no orders after loading
                Text("No orders yet. Go to store to place an order.")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .padding()
                    .multilineTextAlignment(.center)
            } else {
                List(viewModel.orders) { order in
                    NavigationLink(destination: OrderDetailView(order: order)) {
                        HStack(alignment: .center, spacing: 16) {
                            // Loop through line items to show image
                            if let firstLineItem = order.lineItems.first, let imageUrl = firstLineItem.imageUrl, let url = URL(string: imageUrl) {
                                CachedImageView(url: url)
                                    .frame(width: 80, height: 80) // Increased image size
                                    .cornerRadius(12)
                            } else {
                                // If no image is available, show a placeholder
                                Text("No Image")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .frame(width: 80, height: 80) // Increased placeholder size
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Order \(order.orderName)")
                                    .font(.title3) // Larger font size for the order name
                                    .foregroundColor(.primary)
                                Text(order.date, style: .date)
                                    .font(.body) // Larger font size for the date
                                    .foregroundColor(.gray)
                                Text("Status: \(order.fulfillmentStatus)")
                                    .font(.body) // Larger font size for the status
                                    .foregroundColor(.blue)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity) // Ensure the row takes the full width
                    }
                    .listRowSeparator(.hidden)
                }
                .navigationTitle("Order History")
                .listStyle(PlainListStyle())
            }
        }
    }
}






// MARK: - Order Detail View (Receipt View)
struct OrderDetailView: View {
    let order: Order

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Receipt")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                HStack {
                    Text("Order Number:")
                    Spacer()
                    Text(order.orderName)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Date:")
                    Spacer()
                    Text(order.date, style: .date)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Status:")
                    Spacer()
                    Text(order.fulfillmentStatus)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }

                Divider().padding(.vertical, 10)

                Text("Items:")
                    .font(.headline)
                    .padding(.bottom, 8)

                ForEach(order.lineItems) { lineItem in
                    HStack {
                        // Image on the left with Lazy Loading and caching
                        if let imageUrl = lineItem.imageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                        .frame(width: 50, height: 50)
                                case .success(let image):
                                    image.resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80) // Larger image size
                                        .cornerRadius(8)
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80) // Larger fallback image size
                                        .cornerRadius(8)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .padding(.trailing, 8) // Add padding between image and text
                        }

                        // Title and Quantity next to the image
                        VStack(alignment: .leading) {
                            Text(lineItem.title)
                                .font(.body)
                                .foregroundColor(.primary)
                            Text("Qty: \(lineItem.quantity)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()

                        // Price (Prefixed with dollar sign)
                        Text("\(lineItem.price)")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    Divider()
                }

                // Pricing Details (Tax section removed)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Subtotal:")
                        Spacer()
                        Text(order.subtotalAmount.split(separator: " ").first ?? "")
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Shipping:")
                        Spacer()
                        Text(order.totalShippingAmount.split(separator: " ").first ?? "")
                            .fontWeight(.semibold)
                    }

                    Divider().padding(.vertical, 10)

                    HStack {
                        Spacer()
                        Text("Total: \(order.totalAmount.split(separator: " ").first ?? "")")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }

            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .padding()
        }
        .navigationTitle("Order Details")
    }
}

struct CachedImageView: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        if let cachedImage = CacheManager.shared.getCachedImage(for: url) {
            image = cachedImage
        } else {
            downloadImage()
        }
    }

    private func downloadImage() {
        let task = URLSession.shared.dataTask(with: url) { [self] data, _, _ in
            guard let data = data, let uiImage = UIImage(data: data) else { return }
            DispatchQueue.main.async {
              self.image = uiImage
                CacheManager.shared.cacheImage(uiImage, for: url)
            }
        }
        task.resume()
    }
}



// MARK: - Preview
struct OrderHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OrderHistoryView()
        }
    }
}
