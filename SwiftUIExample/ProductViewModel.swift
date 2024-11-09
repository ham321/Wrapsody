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
import Combine
import Foundation
import ShopifyCheckoutSheetKit

var cache: Storefront.Cart?

public class CartManager: ObservableObject {
    let client: StorefrontClient = StorefrontClient()

    static let shared = CartManager()

    // MARK: Properties

    @Published
    var cart: Storefront.Cart?
  
  
  func createCustomer(email: String, firstName: String, lastName: String, password: String, onCompletionHandler: @escaping (Storefront.Customer?) -> Void) {
          let mutation = Storefront.buildMutation { $0
            .customerCreate(input: Storefront.CustomerCreateInput(email: email, password: password, firstName: firstName, lastName: lastName)) { $0
                  .customer { $0
                      .id()
                      .firstName()
                      .lastName()
                      .email()
                  }
                  .userErrors { $0
                      .field()
                      .message()
                  }
              }
          }

    client.execute(mutation: mutation) { result in
        switch result {
        case .success(let mutation):
            if let customer = mutation.customerCreate?.customer {
                // Successfully created customer
                onCompletionHandler(customer)
            } else if let userErrors = mutation.customerCreate?.userErrors, !userErrors.isEmpty {
                // Log detailed user errors
                for error in userErrors {
                    print("Field: \(error.field?.joined(separator: ", ") ?? "Unknown field")")
                    print("Message: \(error.message ?? "No message available")")
                }
                onCompletionHandler(nil)
            } else {
                // Handle other errors
                print("Unknown error occurred.")
                onCompletionHandler(nil)
            }
        case .failure(let error):
            print("Error creating customer: \(error.localizedDescription)")
            onCompletionHandler(nil)
        }
    }

      }
  
  // Login Customer Function
  func loginCustomer(email: String, password: String, onCompletionHandler: @escaping (Storefront.CustomerAccessToken?) -> Void) {
      let loginInput = Storefront.CustomerAccessTokenCreateInput(email: email, password: password)

      let mutation = Storefront.buildMutation { $0
          .customerAccessTokenCreate(input: loginInput) { $0
              .customerAccessToken { $0
                  .accessToken()
              }
              .userErrors { $0
                  .field()
                  .message()
              }
          }
      }

      client.execute(mutation: mutation) { result in
          switch result {
          case .success(let mutation):
              if let accessToken = mutation.customerAccessTokenCreate?.customerAccessToken?.accessToken {
                  // Successfully logged in
                  print("Successfully logged in. Access Token: \(accessToken)")
                  
                  // Save the access token to UserDefaults
                  UserDefaults.standard.set(accessToken, forKey: "customerAccessToken")

                  // Fetch past orders
                  self.fetchPastOrders(customerAccessToken: accessToken) { orders in
                      if let orders = orders {
                          // Handle the orders here (e.g., update the UI or notify another part of the app)
                          print("Fetched past orders: \(orders)")
                      } else {
                          print("Failed to fetch past orders.")
                      }
                  }

                  onCompletionHandler(mutation.customerAccessTokenCreate?.customerAccessToken)
              } else if let userErrors = mutation.customerAccessTokenCreate?.userErrors, !userErrors.isEmpty {
                  // Handle user errors if there are any
                  print("User errors: \(userErrors)")
                  onCompletionHandler(nil)
              } else {
                  // Handle unknown errors
                  print("Unknown error occurred during login.")
                  onCompletionHandler(nil)
              }
          case .failure(let error):
              print("Error logging in: \(error)")
              onCompletionHandler(nil)
          }
      }
  }

  // MARK: - Fetch Past Orders
  func fetchPastOrders(customerAccessToken: String, onCompletionHandler: @escaping ([Storefront.Order]?) -> Void) {
      let query = Storefront.buildQuery { $0
          .customer(customerAccessToken: customerAccessToken) { $0
              .orders(first: 250) { $0.edges { $0.node { $0
                  .id()
                  .name()
                  .processedAt()
                  .totalPrice { $0
                      .amount()
                      .currencyCode()
                  }
                  .totalTax { $0 // Fetch total tax amount if available
                      .amount()
                      .currencyCode()
                  }
                  .fulfillmentStatus() // Added field to fetch order status
                  .lineItems(first: 250) { $0.edges { $0.node { $0
                      .title()
                      .quantity()
                      .variant { $0
                          .id()
                          .title()
                          .price { $0
                              .amount()
                              .currencyCode()
                          }
                      }
                  }}}
              }}}
          }
      }

      client.execute(query: query) { result in
          switch result {
          case .success(let response):
              // Extract orders from the response
              let orders = response.customer?.orders.edges.compactMap { $0.node }
              onCompletionHandler(orders)
          case .failure(let error):
              print("Error fetching past orders: \(error)")
              onCompletionHandler(nil)
          }
      }
  }


  
  
  

    func injectRandomCartItem() {
        if cache == nil {
            getRandomProduct(onCompletionHandler: { item in
                if let variantId = item?.variants.nodes.first?.id {
                    self.addItem(variant: variantId, completionHandler: { cart in
                        cache = cart
                        self.cart = cart
                    })
                }
            })
        } else {
            cart = cache
        }
    }

    // MARK: Cart Actions

    func addItem(variant: GraphQL.ID, completionHandler: ((Storefront.Cart?) -> Void)?) {
        performCartLinesAdd(item: variant) { result in
            switch result {
            case .success(let cart):
                self.cart = cart
            case .failure(let error):
                print(error)
            }
            completionHandler?(self.cart)
        }
    }

    func updateQuantity(variant: GraphQL.ID, quantity: Int32, completionHandler: ((Storefront.Cart?) -> Void)?) {
        performCartUpdate(id: variant, quantity: quantity, handler: { result in
            switch result {
            case .success(let cart):
                self.cart = cart
            case .failure(let error):
                print(error)
            }
            completionHandler?(self.cart)
        })
    }

    func resetCart() {
        self.cart = nil
    }
  
  // MARK: - Collection Actions

  func fetchCollections(onCompletionHandler: @escaping ([Storefront.Collection]?) -> Void) {
      let query = Storefront.buildQuery(inContext: Storefront.InContextDirective(country: Storefront.CountryCode.inferRegion())) { $0
          .collections(first: 250) { $0.edges { $0.node { $0.collectionFragment() } } }
      }

      client.execute(query: query) { result in
          if case .success(let query) = result {
              let collections = query.collections.edges.map { $0.node }
              onCompletionHandler(collections)
          } else {
              onCompletionHandler(nil)
          }
      }
  }
  
  
  


    // MARK: Product actions

    func getRandomProduct(onCompletionHandler: @escaping (Storefront.Product?) -> Void) {
        let query = Storefront.buildQuery(inContext: Storefront.InContextDirective(country: Storefront.CountryCode.inferRegion())) { $0
            .products(first: 250) { $0
                .edges { $0
                    .node { $0.productFragment() }
                }
            }
        }

        client.execute(query: query) { result in
            if case .success(let query) = result {
                let product = query.products.edges.randomElement()?.node
                onCompletionHandler(product)
            }
        }
    }

    typealias CartResultHandler = (Result<Storefront.Cart, Error>) -> Void

    private func performCartUpdate(id: GraphQL.ID, quantity: Int32, handler: @escaping CartResultHandler) {
        let lines = [Storefront.CartLineUpdateInput.create(id: id, quantity: Input(orNull: quantity))]

        if let cartID = cart?.id {
            let mutation = Storefront.buildMutation(inContext: Storefront.InContextDirective(country: Storefront.CountryCode.inferRegion())) { $0
                .cartLinesUpdate(cartId: cartID, lines: lines) { $0
                    .cart { $0.cartManagerFragment() }
                }
            }

            client.execute(mutation: mutation) { result in
                if case .success(let mutation) = result, let cart = mutation.cartLinesUpdate?.cart {
                    handler(.success(cart))
                } else {
                    handler(.failure(URLError(.unknown)))
                }
            }
        } else {
            performCartCreate(items: [id], handler: handler)
        }
    }

    private func performCartLinesAdd(item: GraphQL.ID, handler: @escaping CartResultHandler) {
        if let cartID = cart?.id {
            let lines = [Storefront.CartLineInput.create(merchandiseId: item)]

            let mutation = Storefront.buildMutation(inContext: Storefront.InContextDirective(country: Storefront.CountryCode.inferRegion())) { $0
                .cartLinesAdd(lines: lines, cartId: cartID) { $0
                    .cart { $0.cartManagerFragment() }
                }
            }

            client.execute(mutation: mutation) { result in
                if case .success(let mutation) = result, let cart = mutation.cartLinesAdd?.cart {
                    handler(.success(cart))
                } else {
                    handler(.failure(URLError(.unknown)))
                }
            }
        } else {
            performCartCreate(items: [item], handler: handler)
        }
    }

    private func performCartCreate(items: [GraphQL.ID] = [], handler: @escaping CartResultHandler) {
        let mutation = Storefront.buildMutation(inContext: Storefront.InContextDirective(country: Storefront.CountryCode.inferRegion())) { $0
            .cartCreate(input: defaultCart(items)) { $0
                .cart { $0.cartManagerFragment() }
            }
        }

        client.execute(mutation: mutation) { result in
            if case .success(let mutation) = result, let cart = mutation.cartCreate?.cart {
                handler(.success(cart))
            } else {
                handler(.failure(URLError(.unknown)))
            }
        }
    }

    private func defaultCart(_ items: [GraphQL.ID]) -> Storefront.CartInput {
        return Storefront.CartInput.create(
            lines: Input(orNull: items.map({ Storefront.CartLineInput.create(merchandiseId: $0) }))
        )
    }
  // MARK: Cart Actions
  func removeItem(cartLineId: GraphQL.ID, completionHandler: ((Storefront.Cart?) -> Void)?) {
      performCartLinesRemove(item: cartLineId) { result in
          switch result {
          case .success(let cart):
              self.cart = cart
          case .failure(let error):
              print(error)
          }
          completionHandler?(self.cart)
      }
  }

  private func performCartLinesRemove(item: GraphQL.ID, handler: @escaping CartResultHandler) {
      if let cartID = cart?.id {
          let lines = [item]

          let mutation = Storefront.buildMutation(inContext: Storefront.InContextDirective(country: Storefront.CountryCode.inferRegion())) { $0
              .cartLinesRemove(cartId: cartID, lineIds: lines) { $0
                  .cart { $0.cartManagerFragment() }
              }
          }

          client.execute(mutation: mutation) { result in
              if case .success(let mutation) = result, let cart = mutation.cartLinesRemove?.cart {
                  handler(.success(cart))
              } else {
                  handler(.failure(URLError(.unknown)))
              }
          }
      }
  }
  

}

extension Storefront.CollectionQuery {
    @discardableResult
    func collectionFragment() -> Storefront.CollectionQuery {
        self.id()
            .title()
            .description()
            .products(first: 250) { $0.edges { $0.node { $0.productFragment() } } }
    }
}


// MARK: Extensions for Storefront

extension Storefront.ProductQuery {
    @discardableResult
    func productFragment() -> Storefront.ProductQuery {
        self.id() // Ensure id is included
            .title()
            .description()
            .vendor()
            .featuredImage { $0
                .url()
            }
            .images(first: 250) { $0.edges { $0.node { $0.id().url() } } } // Now includes 'id' and 'url'
            .variants(first: 250) { $0
                $0.nodes { $0
                    .id() // Ensure id is included for variants
                    .title()
                    .price { $0
                        .amount()
                        .currencyCode()
                    }
                    .availableForSale()
                    .image { // Fetching the image for each variant
                        $0
                            .id()
                            .url() // Getting the URL for the image
                    }
                }
            }
            .collections(first: 10) { $0 // Add this line to fetch collections
                $0.edges { $0.node { $0
                    .id() // Assuming you want the collection ID
                    .title() // Assuming you want the collection title
                }}
            }
            .tags() // Fetching tags if they exist in the model
            .productType() // Fetching product type if it exists in the model
    }
}



extension Storefront.CartQuery {
    @discardableResult
    func cartManagerFragment() -> Storefront.CartQuery {
        self
            .id() // Query the cart ID
            .checkoutUrl()
            .totalQuantity()
            .lines(first: 250) { $0
                .nodes { $0
                    .id() // Query the line item ID
                    .quantity()
                    .merchandise { $0
                        .onProductVariant { $0
                            .id() // Query the product variant ID
                            .title()
                            .price { $0
                                .amount()
                                .currencyCode()
                            }
                            .product { $0
                                .id() // Query the product ID if needed
                                .title()
                                .vendor()
                                .featuredImage { $0
                                    .url()
                                }
                            }
                            .availableForSale()
                        }
                    }
                }
            }
            .cost { $0
                .totalAmount { $0
                    .amount()
                    .currencyCode()
                }
                .subtotalAmount { $0
                    .amount()
                    .currencyCode()
                }
                .totalTaxAmount { $0
                    .amount()
                    .currencyCode()
                }
            }
    }
}

extension Storefront.CustomerQuery {
    @discardableResult
    func pastOrdersFragment() -> Storefront.CustomerQuery {
        self
            .id() // Include customer ID
            .firstName() // Include customer's first name
            .lastName() // Include customer's last name
            .email() // Include customer's email
            .orders(first: 250) { $0 // Fetch up to 250 past orders
                $0.edges { $0.node { order in
                    order
                        .id() // Include order ID
                        .processedAt() // Date the order was processed
                        .totalPrice { $0 // Fetch total price details
                            $0.amount() // Total amount
                            $0.currencyCode() // Currency code
                        }
                        .lineItems(first: 250) { $0 // Fetch up to 250 line items for each order
                            $0.edges { $0.node { lineItem in
                                lineItem
                                    .quantity() // Quantity of the line item
                                    .variant { $0 // Include the variant of the line item
                                        .id() // Variant ID
                                        .title() // Variant title
                                    }
                            }}
                        }
                }}
            }
    }
}




extension Storefront.CountryCode {
    static func inferRegion() -> Storefront.CountryCode {
        if #available(iOS 16, *) {
            if let regionCode = Locale.current.region?.identifier {
                return Storefront.CountryCode(rawValue: regionCode) ?? .ca
            }
        }
        return .ca
    }
}

extension Storefront.MoneyV2 {
    func formattedString() -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode.rawValue
        return formatter.string(from: NSDecimalNumber(decimal: amount))
    }
}
