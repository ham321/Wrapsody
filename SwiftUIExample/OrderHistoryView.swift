import SwiftUI

// MARK: - LineItem Model
struct LineItem: Identifiable {
    let id: String
    let title: String
    let variantTitle: String  // New property to store the variant title
    let quantity: Int
    let price: String
    let imageUrl: String?

    init(id: String, title: String, variantTitle: String, quantity: Int, price: Decimal, currencyCode: String, imageUrl: String?) {
        self.id = id
        self.title = title
        self.variantTitle = variantTitle  // Set the variant title
        self.quantity = quantity
        self.price = "$\(Order.formatAmount(price)) \(currencyCode)"
        self.imageUrl = imageUrl
    }
}


// MARK: - Order Model
struct Order: Identifiable {
    let id: UUID
    let date: Date
    let orderId: String
    let orderName: String
    let totalAmount: String
    let subtotalAmount: String
    let totalShippingAmount: String
    let fulfillmentStatus: String
    let lineItems: [LineItem]

    init(id: UUID, date: Date, orderId: String, orderName: String, totalAmount: Decimal, subtotalAmount: Decimal, totalShippingAmount: Decimal, currencyCode: String, fulfillmentStatus: String, lineItems: [LineItem]) {
        self.id = id
        self.date = date
        self.orderId = orderId
        self.orderName = orderName
        self.totalAmount = "$\(Order.formatAmount(totalAmount)) \(currencyCode)"
        self.subtotalAmount = "$\(Order.formatAmount(subtotalAmount)) \(currencyCode)"
        self.totalShippingAmount = "$\(Order.formatAmount(totalShippingAmount)) \(currencyCode)"
        self.fulfillmentStatus = fulfillmentStatus
        self.lineItems = lineItems
    }

    // Helper function to format Decimal amounts to two decimal places
    static func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = ""
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "0.00"
    }
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
    @Published var isLoading: Bool = true

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
          self.isLoading = false

          if let fetchedOrders = fetchedOrders {
              self.orders = fetchedOrders.map { order in
                  let lineItems = order.lineItems.edges.compactMap { edge in
                      let node = edge.node
                      let variantTitle = node.variant?.title ?? "Unknown Variant Title"  // Fetch variant title

                      return LineItem(
                          id: node.variant?.id.rawValue ?? "Unknown ID",
                          title: node.title,
                          variantTitle: variantTitle,  // Store the variant title separately
                          quantity: Int(node.quantity) ?? 0,
                          price: node.variant?.price.amount ?? Decimal(0),
                          currencyCode: node.variant?.price.currencyCode.rawValue ?? "USD",
                          imageUrl: node.variant?.image?.url.absoluteString
                      )
                  }

                  return Order(
                      id: UUID(),
                      date: order.processedAt,
                      orderId: order.id.rawValue,
                      orderName: order.name ?? "Unknown Order Number",
                      totalAmount: order.totalPrice.amount,
                      subtotalAmount: order.subtotalPrice?.amount ?? Decimal(0),
                      totalShippingAmount: order.totalShippingPrice.amount,
                      currencyCode: order.totalPrice.currencyCode.rawValue ?? "USD",
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
                                    .foregroundColor(.wrapsodyPink)
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





struct OrderDetailView: View {
    let order: Order

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Receipt Title
                Text("Receipt")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                    .foregroundColor(.primary)

                // Order Information
                HStack {
                    Text("Order Number:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(order.orderName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Date:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(order.date, style: .date)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Status:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(order.fulfillmentStatus)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.wrapsodyPink)
                }

                Divider().padding(.vertical, 12)

                // Items Section
                Text("Items:")
                    .font(.headline)
                    .fontWeight(.medium)
                    .padding(.bottom, 8)

              ForEach(order.lineItems) { lineItem in
                  HStack(alignment: .top) {
                      // Image on the left with Lazy Loading and caching
                      if let imageUrl = lineItem.imageUrl, let url = URL(string: imageUrl) {
                          AsyncImage(url: url) { phase in
                              switch phase {
                              case .empty:
                                  ProgressView()
                                      .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                      .frame(width: 60, height: 60)
                              case .success(let image):
                                  image.resizable()
                                      .scaledToFit()
                                      .frame(width: 80, height: 80)
                                      .cornerRadius(8)
                              case .failure:
                                  Image(systemName: "photo")
                                      .resizable()
                                      .scaledToFit()
                                      .frame(width: 80, height: 80)
                                      .cornerRadius(8)
                              @unknown default:
                                  EmptyView()
                              }
                          }
                          .padding(.trailing, 12)
                      }

                      // Title and Variant Title
                      VStack(alignment: .leading) {
                          // Main title with a bolder font style
                          Text(lineItem.title)
                              .font(.body)
                              .fontWeight(.semibold)
                              .foregroundColor(.primary)

                          // Variant title as a sub-headline with a lighter color, stretched to the right
                          Text(lineItem.variantTitle)
                              .font(.subheadline)
                              .fontWeight(.regular)
                              .foregroundColor(.secondary)
                              .padding(.top, 2)
                              .frame(maxWidth: .infinity, alignment: .leading) // Make variant title stretch
                      }

                      Spacer()

                      // Price and Quantity below each other in a VStack
                      VStack(alignment: .trailing) {
                          // Price (Prefixed with dollar sign)
                          Text("\(lineItem.price)")
                              .font(.body)
                              .fontWeight(.semibold)
                              .foregroundColor(.primary)

                          // Quantity with a subtle appearance
                          Text("Qty: \(lineItem.quantity)")
                              .font(.caption)
                              .foregroundColor(.secondary)
                      }
                  }
                  Divider().padding(.vertical, 8)
              }


                // Pricing Details
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Subtotal:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(order.subtotalAmount.split(separator: " ").first ?? "")
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }

                    HStack {
                        Text("Shipping:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        let shippingAmount = order.totalShippingAmount.split(separator: " ").first ?? ""
                        Text(shippingAmount == "$0.00" ? "Free" : shippingAmount)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }

                    Divider().padding(.vertical, 10)

                    HStack {
                        Spacer()
                        Text("Total: \(order.totalAmount.split(separator: " ").first ?? "")")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.wrapsodyGreen)
                    }
                }

            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .padding([.top, .horizontal])
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
