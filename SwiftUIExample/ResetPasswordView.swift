import SwiftUI
import FirebaseAuth

struct ResetPasswordView: View {
    @State private var email: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
              LinearGradient(gradient: Gradient(colors: [Color.wrapsodyBlue, Color.wrapsodyGold]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                // Main content
                VStack {
                    // Logo or Icon
                    Image(systemName: "lock.fill") // Placeholder SF Symbol
                        .font(.system(size: 100))
                        .foregroundColor(.black)
                        .padding(.bottom, 40)
                    
                    // Title
                    Text("Reset Password")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.bottom, 20)
                    
                    // Email text field
                    TextField("Enter your email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                        .padding(.horizontal, 20)
                    
                    // Reset password button
                    Button(action: resetPassword) {
                        Text("Send Reset Link")
                            .foregroundColor(.white)
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.wrapsodyGold)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 30)
                    
                    Spacer()
                }
                .padding(.top, geometry.size.height * 0.1) // Adjust padding based on screen height
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Reset Password"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }

    // Function to handle password reset
    private func resetPassword() {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                alertMessage = error.localizedDescription
            } else {
                alertMessage = "Password reset link sent! Check your email."
            }
            showAlert = true
        }
    }
}

struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ResetPasswordView()
                .previewDevice("iPhone 14")
            ResetPasswordView()
                .previewDevice("iPad Pro (11-inch) (4th generation)")
        }
    }
}

// Extension for custom colors
extension Color {
    static let emerald = Color(red: 80/255, green: 200/255, blue: 120/255) // Emerald Green
}
