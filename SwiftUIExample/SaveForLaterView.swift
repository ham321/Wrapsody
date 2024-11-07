import Foundation
import SwiftUI
import Buy

struct SaveForLaterView: View {
    @ObservedObject var cartManager: CartManager

    var body: some View {
        NavigationView {
            Group {
                if cartManager.savedItems.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(cartManager.savedItems, id: \.id) { item in
                            let variant = item.merchandise as? Storefront.ProductVariant

                            VStack(spacing: 15) {
                                HStack {
                                    if let imageUrl = variant?.product.featuredImage?.url {
                                        AsyncImage(url: imageUrl) { image in
                                            image.image?
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(8)
                                                .clipped()
                                        }
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(8)
                                    } else {
                                        Rectangle()
                                            .foregroundColor(.gray)
                                            .overlay(
                                                Text("No Image Available")
                                                    .foregroundColor(.white)
                                                    .multilineTextAlignment(.center)
                                                    .frame(maxWidth: 80, maxHeight: 80)
                                                    .padding(4)
                                            )
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(8)
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(variant?.product.title ?? "")
                                            .font(.body)
                                            .bold()
                                            .lineLimit(2)
                                            .truncationMode(.tail)

                                        if let price = variant?.price.formattedString() {
                                            Text("\(price)")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }

                                        Text("Quantity: \(item.quantity)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.leading, 5)

                                    Spacer()

                                    Button(action: {
                                        moveToCart(item: item)
                                    }) {
                                        Text("Move to Cart")
                                            .foregroundColor(.wrapsodyBlue)
                                    }
                                }
                                .padding(.vertical, 10)
                                .padding([.leading, .trailing], 10)
                                .background(Color.white.opacity(0.6))
                                .cornerRadius(10)
                                .shadow(color: Color.wrapsodyGold.opacity(0.9), radius: 5, x: 0, y: 2)
                            }
                            .padding(.bottom, 5)
                        }
                        .onDelete(perform: deleteSavedItem)
                    }
                }
            }
            .navigationTitle("Saved for Later")
        }
    }

    private var emptyStateView: some View {
        VStack {
            Image(systemName: "bookmark.slash")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)
                .padding(.bottom, 20)

            Text("No items saved for later.")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)

            Text("Items you save for later will appear here.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
    }

    private func moveToCart(item: BaseCartLine) {
        if let variant = item.merchandise as? Storefront.ProductVariant {
            cartManager.addItem(variant: variant.id) { cart in
                // Optional: use print or other logic here
            }

            if let index = cartManager.savedItems.firstIndex(where: { $0.id == item.id }) {
                cartManager.savedItems.remove(at: index)
            }
        }
    }

    private func deleteSavedItem(at offsets: IndexSet) {
        cartManager.savedItems.remove(atOffsets: offsets)
    }
}
