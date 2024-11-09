import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct LoggedInView: View {
    @State private var userName: String = "Profile" // Default value
    @State private var hasAcceptedEula: Bool = false // Track EULA acceptance
    @State private var isLoading: Bool = true // Track loading state
    private var db = Firestore.firestore()
 

    var body: some View {
        VStack {
            if isLoading {
                // Show loading indicator while checking EULA status
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .onAppear {
                        checkEulaAcceptance() // Fetch EULA status on appear
                    }
            } else {
                // Show the main content
                if hasAcceptedEula {
                    // Show TabView if EULA is accepted
                  RootTabView(userName: userName) // Pass userName here
                                              .navigationBarBackButtonHidden(true)
                                              .onAppear {
                                                  fetchUserName() // Fetch user name on appear
                                              }
                        
                    
                    .navigationBarBackButtonHidden(true)
                    .onAppear {
                        fetchUserName() // Fetch user name on appear
                    }
                } else {
                    // Show EULA view if not accepted
                    EulaView(hasAcceptedEula: $hasAcceptedEula, onAccept: {
                        storeEulaAcceptance() // Store EULA acceptance when accepted
                    })
                }
            }
        }
    }
    
    private func fetchUserName() {
        guard let userEmail = Auth.auth().currentUser?.email else {
            print("No current user email found.")
            return
        }
        
        db.collection("users")
            .whereField("email", isEqualTo: userEmail)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error.localizedDescription)")
                    return
                }
                
                if let documents = querySnapshot?.documents, !documents.isEmpty {
                    let document = documents.first
                    if let data = document?.data() {
                        self.userName = data["firstName"] as? String ?? "Profile"
                        print("User name fetched: \(self.userName)")
                    }
                }
            }
    }

    private func checkEulaAcceptance() {
        guard let userEmail = Auth.auth().currentUser?.email else {
            print("No current user email found.")
            isLoading = false
            return
        }
        
        db.collection("users")
            .whereField("email", isEqualTo: userEmail)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error.localizedDescription)")
                    isLoading = false
                    return
                }
                
                if let documents = querySnapshot?.documents, !documents.isEmpty {
                    if let data = documents.first?.data() {
                        DispatchQueue.main.async {
                            // Fetch and set the EULA acceptance status
                            self.hasAcceptedEula = data["hasAcceptedEula"] as? Bool ?? false
                            self.isLoading = false // Set loading to false after data is fetched
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false // No documents found, stop loading
                    }
                }
            }
    }
    
    private func storeEulaAcceptance() {
        guard let userEmail = Auth.auth().currentUser?.email else {
            print("No current user email found.")
            return
        }
        
        db.collection("users")
            .whereField("email", isEqualTo: userEmail)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error.localizedDescription)")
                    return
                }
                
                if let document = querySnapshot?.documents.first {
                    let documentID = document.documentID
                    db.collection("users").document(documentID).updateData(["hasAcceptedEula": true]) { error in
                        if let error = error {
                            print("Error updating document: \(error.localizedDescription)")
                        } else {
                            print("EULA acceptance status updated.")
                            DispatchQueue.main.async {
                                self.hasAcceptedEula = true // Update the state immediately
                            }
                        }
                    }
                }
            }
    }
}

struct RootTabView: View {
    @State var isShowingCheckout = false
    @State var checkoutURL: URL?
    @ObservedObject private var cartManager = CartManager.shared
    var userName: String // Accept userName as a parameter

    var body: some View {
        TabView {
            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "square.grid.2x2")
                }

            NavigationView {
                CartView(cartManager: cartManager, checkoutURL: $checkoutURL, isShowingCheckout: $isShowingCheckout)
                    .navigationTitle("Cart")
                    .navigationBarTitleDisplayMode(.inline)
                    .padding(20)
                    .toolbar {
                        if cartManager.cart?.lines != nil {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Text("Clear")
                                    .font(.body)
                                    .foregroundStyle(Color.accentColor)
                                    .onTapGesture {
                                        cartManager.resetCart()
                                    }
                            }
                        }
                    }
            }
            .tabItem {
                Label("Cart", systemImage: "cart")
            }
            .badge(Int(cartManager.cart?.totalQuantity ?? 0))
          


            // Pass userName to ProfileView
            ProfileView()
                .tabItem {
                    Label(userName, systemImage: "person.fill")
                }
        }
    }
}


struct LoggedInView_Previews: PreviewProvider {
    static var previews: some View {
        LoggedInView()
    }
}
