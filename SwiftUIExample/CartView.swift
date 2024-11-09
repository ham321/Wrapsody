/*
MIT License

Copyright 2023 - Present, Shopify Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import Buy
import SwiftUI
import ShopifyCheckoutSheetKit

struct CartView: View {
    @State var cartCompleted: Bool = false
    @State var isBusy: Bool = false

    @ObservedObject var cartManager: CartManager
    @Binding var checkoutURL: URL? {
        didSet {
            cartCompleted = false
        }
    }
    @Binding var isShowingCheckout: Bool

    var body: some View {
        // Check if there are items in the cart
        if let lines = cartManager.cart?.lines.nodes, !lines.isEmpty {
            ScrollView {
                VStack {
                    CartLines(lines: lines, isBusy: $isBusy, cartManager: cartManager, checkoutURL: $checkoutURL)

                    Spacer()

                    VStack {
                        Button(action: {
                            if let url = checkoutURL {
                                isShowingCheckout = true
                            } else {
                                print("Checkout URL is not available.")
                            }
                        }, label: {
                            Text("Checkout")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(isBusy || checkoutURL == nil ? Color.gray : Color.wrapsodyBlue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .bold()
                        })
                        .disabled(isBusy || checkoutURL == nil)
                        .accessibilityIdentifier("checkoutButton")
                        .sheet(isPresented: $isShowingCheckout) {
                            if let url = checkoutURL {
                                CheckoutSheet(checkout: url)
                                    .title("SwiftUI")
                                    .colorScheme(.automatic)
                                    .tintColor(UIColor(red: 0.33, green: 0.20, blue: 0.92, alpha: 1.00))
                                    .onCancel {
                                        if cartCompleted {
                                            cartManager.resetCart()
                                            cartCompleted = false
                                        }
                                        isShowingCheckout = false
                                    }
                                    .onPixelEvent { event in
                                        switch event {
                                        case .standardEvent(let event):
                                            print("WebPixel - (standard)", event.name ?? "")
                                        case .customEvent(let event):
                                            print("WebPixel - (custom)", event.name ?? "")
                                        }
                                    }
                                    .onLinkClick { url in
                                        if UIApplication.shared.canOpenURL(url) {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                    .onComplete { checkout in
                                        print("Checkout completed - Order id: \(String(describing: checkout.orderDetails.id))")
                                        cartCompleted = true
                                    }
                                    .onFail { error in
                                        print(error)
                                    }
                                    .edgesIgnoringSafeArea(.all)
                                    .accessibility(identifier: "CheckoutSheet")
                            }
                        }
                        .padding(.top, 15)
                        .padding(.horizontal, 5)
                    }

                    Spacer()
                }
                .padding(10)
                .onAppear {
                    if let cart = cartManager.cart {
                        checkoutURL = cart.checkoutUrl // Assuming checkoutUrl is non-optional
                        ShopifyCheckoutSheetKit.preload(checkout: cart.checkoutUrl) // Use directly if it's non-optional
                    }
                }
            }
        } else {
            // Show the empty state view when the cart is empty
            EmptyState()
        }
    }
}

struct CartLines: View {
    var lines: [BaseCartLine]
    @State var updating: GraphQL.ID? {
        didSet {
            isBusy = updating != nil
        }
    }
    @Binding var isBusy: Bool
    @ObservedObject var cartManager: CartManager
    @Binding var checkoutURL: URL?

    @State private var showingConfirmationDialog: Bool = false
    @State private var itemToRemove: GraphQL.ID? = nil
    @State private var savedItems: Set<GraphQL.ID> = [] // Track saved items

    var body: some View {
        ForEach(lines, id: \.id) { node in
            let variant = node.merchandise as? Storefront.ProductVariant
            
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

                        if let variantTitle = variant?.title, variantTitle != "Default Title" {
                            Text(variant?.availableForSale == true ? variantTitle : "\(variantTitle) (OUT OF STOCK)")
                                .font(.subheadline)
                                .foregroundColor(variant?.availableForSale == true ? .gray : .red)
                        } else {
                            Text(variant?.product.title ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        if let price = variant?.price.formattedString() {
                            HStack {
                                Text("\(price)")
                                    .foregroundColor(.gray)

                                Spacer()

                                HStack(spacing: 10) {
                                    if node.quantity > 1 {
                                        Button(action: {
                                            updateQuantity(for: node, increment: false)
                                        }) {
                                            Text("-")
                                                .font(.title2)
                                                .frame(width: 30, height: 30)
                                                .foregroundColor(Color.wrapsodyBlue.opacity(1.0))
                                                .background(Color.wrapsodyGold.opacity(0.5))
                                                .clipShape(Circle())
                                        }
                                    } else {
                                        Button(action: {
                                            itemToRemove = node.id
                                            showingConfirmationDialog = true
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.title2)
                                                .frame(width: 30, height: 30)
                                                .background(Color.wrapsodyGold.opacity(0.5))
                                                .foregroundColor(Color.wrapsodyBlue.opacity(1.0))
                                                .clipShape(Circle())
                                        }
                                    }

                                    VStack {
                                        if updating == node.id {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                                .scaleEffect(0.8)
                                        } else {
                                            Text("\(node.quantity)")
                                                .frame(width: 30)
                                        }
                                    }

                                    Button(action: {
                                        updateQuantity(for: node, increment: true)
                                    }) {
                                        Text("+")
                                            .font(.title2)
                                            .frame(width: 30, height: 30)
                                            .background(Color.wrapsodyGold.opacity(0.5))
                                            .foregroundColor(Color.wrapsodyBlue.opacity(1.0))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }
                    }
                    .padding(.leading, 5)
                    .padding(.bottom, 0)
                }
                .padding(.bottom, 10)


            }
            .padding([.leading, .trailing], 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.6))
            .cornerRadius(10)
            .shadow(color: Color.wrapsodyGold.opacity(0.9), radius: 5, x: 0, y: 2)
        }
        .alert(isPresented: $showingConfirmationDialog) {
            Alert(
                title: Text("Remove Item"),
                message: Text("Are you sure you want to remove this item from your cart?"),
                primaryButton: .destructive(Text("Remove")) {
                    if let itemToRemove = itemToRemove {
                        cartManager.removeItem(cartLineId: itemToRemove) { cart in
                            cartManager.cart = cart
                            checkoutURL = cart?.checkoutUrl
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func updateQuantity(for node: BaseCartLine, increment: Bool) {
        guard updating != node.id else { return }

        updating = node.id
        ShopifyCheckoutSheetKit.invalidate()

        let newQuantity = increment ? node.quantity + 1 : max(node.quantity - 1, 1)
        cartManager.updateQuantity(variant: node.id, quantity: newQuantity) { cart in
            cartManager.cart = cart
            updating = nil
            checkoutURL = cart?.checkoutUrl
        }
    }

    
}






struct EmptyState: View {
    var body: some View {
        VStack(alignment: .center) {
            SwiftUI.Image(systemName: "cart")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.gray)
                .padding(.bottom, 6)
            Text("Your cart is empty.")
                .font(.caption)
        }
    }
}



struct CartViewPreviewContent: View {
    @State var isShowingCheckout = false
    @State var checkoutURL: URL?
    @State var isBusy: Bool = false
    @StateObject var cartManager = CartManager.shared

    init() {
        cartManager.injectRandomCartItem()
    }

    var body: some View {
        CartView(cartManager: cartManager, checkoutURL: $checkoutURL, isShowingCheckout: $isShowingCheckout)
    }
}

