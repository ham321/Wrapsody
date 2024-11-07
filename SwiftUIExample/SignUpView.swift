import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// Sign-Up View
struct SignUpView: View {
  @State private var email: String = ""
  @State private var password: String = ""
  @State private var confirmPassword: String = ""
  @State private var firstName: String = ""
  @State private var lastName: String = ""
  @State private var showAlert = false
  @State private var alertMessage = ""
  @State private var isUserSignedUp = false
  @State private var hasAcceptedEula = false
  @Environment(\.presentationMode) private var presentationMode
  
  private let db = Firestore.firestore()
  
  var body: some View {
    NavigationView {
      ZStack {
        // Background Gradient
        LinearGradient(gradient: Gradient(colors: [Color.wrapsodyBlue, Color.wrapsodyGold]), startPoint: .topLeading, endPoint: .bottomTrailing)
          .ignoresSafeArea()
        
        VStack {
          ScrollView {
            VStack(spacing: 20) {
              Text("Sign Up")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding(.bottom, 40)
              
              inputField("First Name", text: $firstName)
              inputField("Last Name", text: $lastName)
              inputField("Email", text: $email, keyboardType: .emailAddress)
              inputField("Password", text: $password, isSecure: true)
              inputField("Confirm Password", text: $confirmPassword, isSecure: true)
              
              // Create Account Button
              Button(action: {
                signUpUser()
              }) {
                Text("Create Account")
                  .foregroundColor(.black)
                  .font(.headline)
                  .fontWeight(.bold)
                  .frame(maxWidth: .infinity)
                  .padding()
                  .background(LinearGradient(gradient: Gradient(colors: [Color.wrapsodyBlue, Color.wrapsodyGold]), startPoint: .leading, endPoint: .trailing))
                  .cornerRadius(12)
                  .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
              }
              .padding(.horizontal, 20)
              .padding(.top, 20)
              
              // EULA Acceptance
              HStack {
                Button(action: {
                  hasAcceptedEula.toggle()
                }) {
                  Image(systemName: hasAcceptedEula ? "checkmark.square" : "square")
                    .foregroundColor(.black)
                }
                Text("I accept the End User License Agreement")
                  .foregroundColor(.black)
              }
              .padding(.top, 10)
              
              // EULA and Terms Links
              VStack(spacing: 2) {
                Text("By continuing, you agree to our")
                  .foregroundColor(.black)
                  .font(.footnote)
                  .multilineTextAlignment(.center)
                
                HStack {
                  NavigationLink(destination: EulaSettingsView()) {
                    Text("End User License Agreement")
                      .fontWeight(.bold)
                      .foregroundColor(.black)
                  }
                  Text("and")
                    .foregroundColor(.black)
                    .font(.footnote)
                  
                  NavigationLink(destination: TermsView()) {
                    Text("Terms")
                      .fontWeight(.bold)
                      .foregroundColor(.black)
                  }
                }
                .font(.footnote)
                .multilineTextAlignment(.center)
              }
              .padding(.top, 10)
              
              Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 40)
          }
        }
        .alert(isPresented: $showAlert) {
          Alert(
            title: Text("Sign Up"),
            message: Text(alertMessage),
            dismissButton: .default(Text("OK")) {
              if isUserSignedUp {
                presentationMode.wrappedValue.dismiss()
              }
            }
          )
        }
        
        // Navigation to LoginView after successful sign-up
        NavigationLink(destination: LoginView(), isActive: $isUserSignedUp) {
          EmptyView()
        }
      }
      .navigationTitle("") // Keep the title empty for this view
      .navigationBarHidden(true) // Hide the navigation bar for a clean look
    }
    .navigationViewStyle(StackNavigationViewStyle()) // Ensures compatibility on larger screens like iPad
  }
  
  // Helper method for creating text fields
  private func inputField(_ placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default, isSecure: Bool = false) -> some View {
    Group {
      if isSecure {
        SecureField(placeholder, text: text)
      } else {
        TextField(placeholder, text: text)
          .keyboardType(keyboardType)
          .autocapitalization(.none)
      }
    }
    .padding()
    .background(Color.white.opacity(0.9))
    .cornerRadius(12)
    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
  }
  
  // Firebase sign-up method
  func signUpUser() {
    guard password == confirmPassword else {
      alertMessage = "Passwords do not match."
      showAlert = true
      return
    }
    
    guard hasAcceptedEula else {
      alertMessage = "You must accept the End User License Agreement."
      showAlert = true
      return
    }
    
    Auth.auth().createUser(withEmail: email, password: password) { result, error in
      if let error = error {
        alertMessage = error.localizedDescription
        showAlert = true
      } else if let user = result?.user {
        // Save user information to Firestore with email as document ID
        let userData: [String: Any] = [
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "hasAcceptedEula": hasAcceptedEula // Include EULA acceptance status
        ]
        let emailDocumentID = email.lowercased() // Convert email to lowercase to avoid issues with case sensitivity
        db.collection("users").document(emailDocumentID).setData(userData) { error in
          if let error = error {
            alertMessage = "Failed to save user information: \(error.localizedDescription)"
            showAlert = true
          } else {
            // Call the Cart Manager's createCustomer function to create a customer
            CartManager.shared.createCustomer(email: email, firstName: firstName, lastName: lastName, password: password) { customer in
              if let customer = customer {
                // Handle successful customer creation
                alertMessage = "Sign-up successful! You can now log in."
                showAlert = true
                isUserSignedUp = true
              } else {
                alertMessage = "Failed to create customer in Cart."
                showAlert = true
              }
            }
          }
        }
      }
    }
  }
}

extension Color {
    static let emeraldGreen = Color(red: 0.21, green: 0.66, blue: 0.35)
    static let yellow = Color(red: 1.0, green: 0.93, blue: 0.30)
}
