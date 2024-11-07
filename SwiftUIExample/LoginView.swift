import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import GoogleSignIn

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoggingIn: Bool = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToLoggedIn = false
    @State private var stayLoggedIn: Bool = false
    @State private var isLoading: Bool = true
    @State private var showPassword: Bool = false
    
    @AppStorage("isUserLoggedIn") private var isUserLoggedIn: Bool = false
    @AppStorage("stayLoggedIn") private var savedStayLoggedIn: Bool = false
    @AppStorage("savedEmail") private var savedEmail: String = ""
    @AppStorage("savedPassword") private var savedPassword: String = ""
    
    private var db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    LoadingScreenView()
                        .onAppear(perform: handleAutoLogin)
                } else {
                    loginForm
                }
                
                NavigationLink(destination: LoggedInView().navigationBarBackButtonHidden(true), isActive: $navigateToLoggedIn) {
                    EmptyView()
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensures single column on iPad
    }
    
  private var loginForm: some View {
      ZStack {
        LinearGradient(gradient: Gradient(colors: [Color.wrapsodyBlue.opacity(1.0), Color.wrapsodyGold.opacity(1.0)]), startPoint: .topLeading, endPoint: .bottomTrailing)
              .ignoresSafeArea()
          
          VStack(spacing: 30) {
              Spacer() // Pushes content down
              
              Image("appLogo")
                  .resizable()
                  .scaledToFit()
                  .frame(width: 100, height: 100)
              
              Text("Wrapsody")
                  .font(.largeTitle)
                  .fontWeight(.bold)
                  .foregroundColor(.black)
              
              loginFields
                  .padding(.horizontal, 20)
              
              Toggle(isOn: $stayLoggedIn) {
                  Text("Stay Logged In")
                      .foregroundColor(.white)
                      .font(.headline)
              }
              .padding(.horizontal, 20)
              .toggleStyle(CustomToggleStyle(onColor: .wrapsodyBlue, offColor: .wrapsodyGold)) // Adjust colors here

            
              
              loginButton
                  .padding(.horizontal, 20)
              
              VStack(spacing: 20) {
                /*
                  HStack(spacing: 30) {
                      googleSignInButton
                      appleSignInButton
                  }
                  .padding(.top, 15)*/

                  
                  HStack {
                      NavigationLink(destination: ResetPasswordView()) {
                          Text("Forgot Password?")
                              .foregroundColor(.black)
                              .font(.headline)
                      }
                      
                      Spacer()
                      
                      NavigationLink(destination: SignUpView()) {
                          Text("Sign Up")
                              .foregroundColor(.black)
                              .font(.headline)
                      }
                  }
                  .padding(.top, 30)
                  .padding(.horizontal, 20)
              }
              
              Spacer() // Pushes content to the top
          }
          .padding(.horizontal) // Adjust horizontal padding
          .padding(.top, 20) // Add top padding to move content down
          
          // EULA and Terms links at the bottom
          VStack {
              Spacer() // Push this to the bottom
              VStack(spacing: 5) {
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
          }
      }
  }




    private var loginFields: some View {
        VStack(spacing: 15) {
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
            
            ZStack(alignment: .trailing) {
                if showPassword {
                    TextField("Password", text: $password)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
                } else {
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
                }
                
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(.wrapsodyGold)
                        .padding(.trailing, 10)
                }
            }
        }
    }

    private var loginButton: some View {
        Button(action: {
            isLoggingIn = true
            loginUser()
        }) {
            Text(isLoggingIn ? "Logging in..." : "Login")
                .foregroundColor(.white)
                .font(.headline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    Group {
                        if isLoggingIn {
                            Color.gray
                        } else {
                            LinearGradient(
                              gradient: Gradient(colors: [Color.wrapsodyBlue, Color.wrapsodyGold]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
        }
        .disabled(isLoggingIn)
    }

    private var googleSignInButton: some View {
        Button(action: signInWithGoogle) {
            HStack {
                Image("google") // Add your Google logo image here
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .frame(width: 140, height: 45)
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
        }
    }

    private var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            handleAppleSignIn(result: result)
        }
        .frame(width: 140, height: 45)
        .signInWithAppleButtonStyle(.black)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authResults):
            if let credential = authResults.credential as? ASAuthorizationAppleIDCredential {
                let email = credential.email
                let fullName = credential.fullName
                
                guard let idToken = credential.identityToken else {
                    alertMessage = "Error: Missing Apple ID token."
                    showAlert = true
                    return
                }
                
                let tokenString = String(data: idToken, encoding: .utf8) ?? ""
                let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, accessToken: tokenString)
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        alertMessage = "Error authenticating with Apple: \(error.localizedDescription)"
                        showAlert = true
                    } else {
                        if let email = email {
                            saveUserDataToFirestore(email: email, fullName: fullName)
                        }
                        savedStayLoggedIn = stayLoggedIn
                        navigateToLoggedIn = true
                    }
                }
            }
        case .failure(let error):
            alertMessage = "Error signing in with Apple: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func handleAutoLogin() {
        if Auth.auth().currentUser != nil && savedStayLoggedIn {
            Auth.auth().signIn(withEmail: savedEmail, password: savedPassword) { result, error in
                isLoading = false
                if let error = error {
                    alertMessage = "Error authenticating: \(error.localizedDescription)"
                    showAlert = true
                    isUserLoggedIn = false
                    savedStayLoggedIn = false
                    savedEmail = ""
                    savedPassword = ""
                } else {
                    navigateToLoggedIn = true
                }
            }
        } else {
            isLoading = false
        }
    }
    
  private func loginUser() {
      // Set the logging in state
      isLoggingIn = true

      // Attempt to log in with Firebase
      Auth.auth().signIn(withEmail: email, password: password) { [self] result, error in
          self.isLoggingIn = false // Reset the logging in state

          if let error = error {
              // Handle Firebase login error
              self.alertMessage = error.localizedDescription
              self.showAlert = true
              return // Exit early if Firebase login fails
          }

          // Firebase login successful
          if self.stayLoggedIn {
              self.savedStayLoggedIn = true
              self.savedEmail = self.email
              self.savedPassword = self.password
          } else {
              self.savedStayLoggedIn = false
              self.savedEmail = ""
              self.savedPassword = ""
          }

          // Now that Firebase login is successful, call Shopify login
          CartManager.shared.loginCustomer(email: self.email, password: self.password) { accessToken in
              DispatchQueue.main.async {
                  if accessToken != nil {
                      // Both logins were successful
                      self.isUserLoggedIn = true
                      self.navigateToLoggedIn = true
                  } else {
                      // Handle Shopify login failure
                      self.alertMessage = "Failed to log in with Shopify. Please check your credentials."
                      self.showAlert = true
                  }
              }
          }
      }
  }

    
    private func signInWithGoogle() {
        guard let rootViewController = UIApplication.shared.getRootViewController() else {
            alertMessage = "Error: Unable to find the root view controller."
            showAlert = true
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signResult, error in
            if let error = error {
                alertMessage = "Error signing in with Google: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            guard let user = signResult?.user,
                  let idToken = user.idToken?.tokenString else {
                alertMessage = "Error: Missing Google ID token."
                showAlert = true
                return
            }
            
            let accessToken = user.accessToken.tokenString
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    alertMessage = "Error authenticating with Google: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                let email = user.profile?.email ?? ""
                let fullNameString = user.profile?.name ?? ""
                let fullNameComponents = convertFullNameToComponents(fullNameString)
                
                saveUserDataToFirestore(email: email, fullName: fullNameComponents)
                
                savedStayLoggedIn = stayLoggedIn
                navigateToLoggedIn = true
            }
        }
    }
    
    private func convertFullNameToComponents(_ fullName: String) -> PersonNameComponents? {
        let nameParts = fullName.split(separator: " ")
        guard nameParts.count > 0 else { return nil }
        
        let givenName = nameParts.first.map(String.init)
        let familyName = nameParts.dropFirst().joined(separator: " ")
        
        var components = PersonNameComponents()
        components.givenName = givenName
        components.familyName = familyName
        
        return components
    }
    
  private func saveUserDataToFirestore(email: String, fullName: PersonNameComponents?) {
      let userRef = db.collection("users").document(email)
      let firstName = fullName?.givenName ?? ""
      let lastName = fullName?.familyName ?? ""

      // Use the merge option to avoid overwriting existing fields
      userRef.setData([
          "email": email,
          "firstName": firstName,
          "lastName": lastName
      ], merge: true) { error in
          if let error = error {
              alertMessage = "Error saving user data: \(error.localizedDescription)"
              showAlert = true
          } else {
              print("User data merged successfully!")
          }
      }
  }

}

extension UIApplication {
    func getRootViewController() -> UIViewController? {
        guard let scene = connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView()
                .previewDevice("iPhone 14")
            LoginView()
                .previewDevice("iPad Air (5th generation)")
        }
    }
}


struct CustomToggleStyle: ToggleStyle {
    var onColor: Color
    var offColor: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .foregroundColor(.white)
                .font(.headline)
            Spacer()
            Rectangle()
                .foregroundColor(configuration.isOn ? onColor : offColor)
                .cornerRadius(20)
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .foregroundColor(.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 12 : -12)
                        .animation(.easeInOut, value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}
