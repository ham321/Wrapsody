import SwiftUI

// MARK: - LineItem Model
struct LineItem: Identifiable {
    let id: String
    let title: String
    let quantity: Int
    let price: String
}

// MARK: - Order Model
struct Order: Identifiable {
    let id: UUID
    let date: Date
    let orderId: String
    let orderName: String
    let totalAmount: String
    let fulfillmentStatus: String // Add this line
    let lineItems: [LineItem]
}


// MARK: - Order ViewModel
class OrderViewModel: ObservableObject {
    @Published var orders: [Order] = []

    init() {
        fetchOrders()
    }

    func fetchOrders() {
        guard let customerAccessToken = UserDefaults.standard.string(forKey: "customerAccessToken") else {
            print("Customer access token not found.")
            return
        }

        CartManager.shared.fetchPastOrders(customerAccessToken: customerAccessToken) { [weak self] fetchedOrders in
            guard let self = self else { return }

            if let fetchedOrders = fetchedOrders {
                self.orders = fetchedOrders.map { order in
                    let lineItems = order.lineItems.edges.compactMap { edge in
                        let node = edge.node
                        return LineItem(
                            id: node.variant?.id.rawValue ?? "Unknown ID",
                            title: node.title,
                            quantity: Int(node.quantity) ?? 0,
                            price: "\(node.variant?.price.amount ?? Decimal(0)) \(node.variant?.price.currencyCode.rawValue ?? "USD")"
                        )
                    }

                    return Order(
                        id: UUID(),
                        date: order.processedAt,
                        orderId: order.id.rawValue,
                        orderName: order.name ?? "Unknown Order Number",
                        totalAmount: "\(order.totalPrice.amount) \(order.totalPrice.currencyCode.rawValue)",
                        fulfillmentStatus: order.fulfillmentStatus.rawValue ?? "Unknown Status", // Fetch fulfillment status
                        lineItems: lineItems
                    )
                }
                // Sort orders by date
                self.orders.sort { $0.date > $1.date }
            } else {
                print("No orders found or error fetching orders.")
            }
        }
    }
}

// MARK: - Order History View
struct OrderHistoryView: View {
    @StateObject private var viewModel = OrderViewModel()

    var body: some View {
        VStack {
            if viewModel.orders.isEmpty {
                // No orders yet message
                Text("No orders yet. Go to store to place an order.")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .padding()
                    .multilineTextAlignment(.center)
            } else {
                List(viewModel.orders) { order in
                    VStack(alignment: .leading, spacing: 10) {
                        // Order Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Order #: \(order.orderName)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Text(order.date, style: .date) // Display date in a more user-friendly format
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("Status: \(order.fulfillmentStatus)") // Display fulfillment status
                                    .font(.caption)
                                    .foregroundColor(.blue) // Style it accordingly
                            }
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 2)

                        Divider() // Divider for a receipt-like look

                        // Display Line Items
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(order.lineItems) { lineItem in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(lineItem.title)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Text("Qty: \(lineItem.quantity)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(lineItem.price)
                                        .font(.body)
                                        .foregroundColor(.blue)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        }
                        .padding(.vertical, 4)

                        // Total Amount
                        HStack {
                            Spacer()
                            Text("Total: \(order.totalAmount)")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding(.top, 8)

                        Divider()
                            .padding(.top, 4) // Footer-like separator
                    }
                    .listRowSeparator(.hidden)
                    .padding(.horizontal, 8)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 1)
                    .padding(.vertical, 4)
                }
                .navigationTitle("Order History") // Set the navigation title
                .background(Color(UIColor.systemGray6))
                .listStyle(InsetGroupedListStyle())
            }
        }
    }
}


// MARK: - Preview for OrderHistoryView
struct OrderHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { // Wrap in NavigationView for previews
            OrderHistoryView()
        }
    }
}
