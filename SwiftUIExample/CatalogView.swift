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
import SDWebImageSwiftUI
import ShopifyCheckoutSheetKit

struct CatalogView: View {
    @ObservedObject var cartManager: CartManager
    @Binding var checkoutURL: URL?
    
    @State private var isAddingToCart = false
    @State private var isShowingCheckout = false
    @State private var isShowingCart = false
    @State var product: Storefront.Product?
    @State private var selectedVariantId: GraphQL.ID?
    @State private var isDescriptionExpanded = false
    @State private var selectedImageIndex: Int = 0 // Track the selected image index

    init(cartManager: CartManager, checkoutURL: Binding<URL?>, product: Storefront.Product? = nil) {
        self.cartManager = cartManager
        self._checkoutURL = checkoutURL
        self._product = State(initialValue: product)
    }

    func onAppear() {
        if product == nil {
            cartManager.getRandomProduct { [self] result in
                product = result
                selectedVariantId = product?.variants.nodes.first?.id
            }
        } else {
            selectedVariantId = product?.variants.nodes.first?.id
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    if let product = product {
                        ScrollView {
                            VStack {
                                // TabView for scrolling through additional images
                                if !product.images.edges.isEmpty {
                                    TabView(selection: $selectedImageIndex) {
                                        ForEach(product.images.edges.indices, id: \.self) { index in
                                            let imageEdge = product.images.edges[index]
                                            if let imageUrl = imageEdge.node.url as? URL {
                                                WebImage(url: imageUrl) { image in
                                                    image
                                                        .resizable()
                                                        .scaledToFit()
                                                } placeholder: {
                                                    Rectangle()
                                                        .foregroundColor(.gray)
                                                        .overlay(
                                                            ProgressView()
                                                                .progressViewStyle(CircularProgressViewStyle(tint: .wrapsodyGold))
                                                        )
                                                }
                                                .onSuccess { image, data, cacheType in
                                                    print("Image loaded successfully")
                                                }
                                                .onFailure { error in
                                                    print("Error loading image: \(error.localizedDescription)")
                                                }
                                                .indicator(.activity)
                                                .transition(.fade(duration: 0.5))
                                                .frame(maxHeight: geometry.size.height * 0.4) // Use GeometryReader for height
                                                .clipped()
                                                .tag(index)
                                            }
                                        }
                                    }
                                    .tabViewStyle(PageTabViewStyle())
                                    .frame(height: geometry.size.height * 0.4) // Set height dynamically
                                    .onAppear {
                                        let appearance = UIPageControl.appearance()
                                        appearance.currentPageIndicatorTintColor = UIColor.wrapsodyBlue
                                        appearance.pageIndicatorTintColor = UIColor.wrapsodyGold
                                    }
                                } else {
                                    Text("No additional images available")
                                        .foregroundColor(.gray)
                                }

                              VStack(alignment: .leading) {
                                  Text(product.vendor)
                                      .font(.caption2)
                                      .bold()
                                      .foregroundColor(.wrapsodyPink)
                                      .padding(.top, 10)
                                      .padding(.horizontal, 10)

                                  Text(product.title)
                                      .font(.title3)
                                      .bold()
                                      .lineLimit(2)
                                      .truncationMode(.tail)
                                      .padding(.top, 0)
                                      .padding(.horizontal, 10)

                                  Button(action: {
                                      withAnimation {
                                          isDescriptionExpanded.toggle()
                                      }
                                  }) {
                                      Text(isDescriptionExpanded ? "Hide Description" : "Show Description")
                                          .foregroundColor(.wrapsodyGold)
                                          .padding(.top, 5)
                                          .padding(.horizontal, 10)
                                  }

                                  if isDescriptionExpanded {
                                      Text(product.description)
                                          .padding(.top, 2)
                                          .foregroundColor(.gray)
                                          .padding(.horizontal, 10)
                                          .transition(.slide)
                                          .animation(.easeInOut)
                                  }

                                  if product.variants.nodes.count > 1 {
                                      // Move the "Select an option" label to the left side
                                      Text("Select an option:")
                                          .font(.headline)
                                          .padding(.top, 5)
                                          .padding(.leading, 10) // Align with leading
                                          .foregroundColor(.wrapsodyBlue)
                                  }

                                  if product.variants.nodes.count > 1 {
                                      // Horizontal ScrollView for variants
                                      ScrollView(.horizontal, showsIndicators: false) {
                                          HStack(spacing: 10) {
                                              ForEach(product.variants.nodes, id: \.id) { variant in
                                                  let variantTitle = variant.availableForSale ? variant.title : "\(variant.title) (OUT OF STOCK)"
                                                  
                                                  Button(action: {
                                                      selectedVariantId = variant.id
                                                      // Update the selected image index based on the new variant
                                                      if let firstImage = variant.image {
                                                          if let index = product.images.edges.firstIndex(where: { $0.node.id == firstImage.id }) {
                                                              selectedImageIndex = index
                                                          }
                                                      }
                                                  }) {
                                                      Text(variantTitle)
                                                          .foregroundColor(.white)
                                                          .padding()
                                                          .frame(minWidth: geometry.size.width * 0.25) // Dynamic width
                                                          .background(selectedVariantId == variant.id ? Color.wrapsodyGold : (variant.availableForSale ? Color.wrapsodyBlue : Color.gray)) // Use gray for out of stock
                                                          .cornerRadius(10)
                                                          .overlay(
                                                              RoundedRectangle(cornerRadius: 10)
                                                                  .stroke(selectedVariantId == variant.id ? Color.wrapsodyGold : Color.gray, lineWidth: 2)
                                                          )
                                                          .lineLimit(1)
                                                          .truncationMode(.tail)
                                                          .strikethrough(!variant.availableForSale, color: .white) // Strikethrough if out of stock
                                                  }
                                                  .disabled(false) // Allow selection even if out of stock
                                              }
                                          }
                                          .padding(.horizontal, 10)
                                      }
                                      .padding(.vertical, 10)
                                  }
                              }


                                let selectedVariant = product.variants.nodes.first { $0.id == selectedVariantId }
                                let price = selectedVariant?.price.formattedString() ?? "Out of Stock"

                                Button(action: {
                                    isAddingToCart = true
                                    // Allow adding to cart regardless of stock status
                                    cartManager.addItem(variant: selectedVariantId!) { cart in
                                        isAddingToCart = false
                                        checkoutURL = cart?.checkoutUrl
                                    }
                                }, label: {
                                    if selectedVariant?.availableForSale == false {
                                        Text("Out of Stock - \(price)")
                                            .font(.headline)
                                            .padding()
                                            .frame(maxWidth: geometry.size.width * 0.8) // Dynamic max width
                                            .background(Color.gray)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                            .disabled(false) // Enable button for selection
                                    } else {
                                        if isAddingToCart {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .padding()
                                                .frame(maxWidth: geometry.size.width * 0.8) // Dynamic max width
                                                .background(Color.wrapsodyBlue)
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                        } else {
                                            Text("Add to cart - \(price)")
                                                .font(.headline)
                                                .padding()
                                                .frame(maxWidth: geometry.size.width * 0.8) // Dynamic max width
                                                .background(Color.wrapsodyBlue)
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                        }
                                    }
                                })
                                .accessibilityIdentifier("addToCartButton")
                                .disabled(false) // Enable button regardless of stock status
                                .padding()

                                .sheet(isPresented: $isShowingCart) {
                                    NavigationView {
                                        CartView(
                                            cartManager: cartManager,
                                            checkoutURL: $checkoutURL,
                                            isShowingCheckout: $isShowingCheckout
                                        )
                                        .navigationBarTitleDisplayMode(.inline)
                                        .navigationTitle("Cart")
                                    }
                                }
                            }
                            .padding(.bottom, 100)
                        }
                    } else {
                        ProgressView()
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        BadgeButton(badgeCount: Int(cartManager.cart?.totalQuantity ?? 0), action: {
                            isShowingCart = true
                        })
                        .foregroundColor(.wrapsodyBlue)
                        .accessibilityIdentifier("cartIcon")
                    }
                }
                .navigationTitle("Product Details")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    onAppear()
                }
            }
            .preferredColorScheme(.light)
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

struct BadgeButton: View {
    var badgeCount: Int
    var action: (() -> Void)?

    var body: some View {
        Button(action: action ?? {}) {
            ZStack {
                SwiftUI.Image(systemName: "cart.fill")

                if badgeCount > 0 {
                    Text("\(badgeCount)")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                        .frame(width: 20, height: 20)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 10, y: -10)
                }
            }
        }
    }
}


struct CatalogViewPreview: PreviewProvider {
    static var previews: some View {
        CatalogViewPreviewContent()
    }
}

struct CatalogViewPreviewContent: View {
    @State var isShowingCheckout = false
    @State var checkoutURL: URL?
    @StateObject var cartManager = CartManager.shared

    var body: some View {
        CatalogView(cartManager: cartManager, checkoutURL: $checkoutURL)
    }
}
