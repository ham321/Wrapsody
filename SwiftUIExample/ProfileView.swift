//  ProfileView.swift
//  Lost and Found
//
//  Created by Hamilton Center on 8/16/24.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
  @State private var isLoggingOut = false
  @State private var isDeletingAccount = false
  @State private var showAlert = false
  @State private var alertMessage = ""
  @State private var showConfirmationAlert = false

  @Environment(\.presentationMode) var presentationMode
  
  var body: some View {
    VStack {
      // Header with Profile Title and Settings Button
      HStack {
        Text("Profile")
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundColor(.wrapsodyGold)
          .padding(.leading, 10)
        
        Spacer()
        
        NavigationLink(destination: SettingsView()) {
          Image(systemName: "gear")
            .font(.title)
            .foregroundColor(.wrapsodyGreen)
            .padding(.trailing, 10)
        }
      }
      .padding(.horizontal, 15)
      .padding(.top, 10)
      
      // User Information Section
      VStack(alignment: .center, spacing: 20) {
        if let user = Auth.auth().currentUser {
          Text("Email: \(user.email ?? "N/A")")
            .font(.headline)
          Text("User ID: \(user.uid)")
            .font(.headline)
        } else {
          Text("User not logged in.")
            .font(.headline)
        }
      }
      .padding()

      Spacer()
      
      // Logout and Delete Account Buttons
      HStack {
        Button(action: { showConfirmationAlert = true }) {
          Text(isDeletingAccount ? "Deleting account..." : "Delete Account")
            .foregroundColor(.wrapsodyPink)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .disabled(isDeletingAccount)
        
        Button(action: {
          isLoggingOut = true
          logoutUser()
        }) {
          Text(isLoggingOut ? "Logging out..." : "Logout")
            .foregroundColor(.white)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.wrapsodyPink)
            .cornerRadius(12)
        }
        .disabled(isLoggingOut)
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 20)
    }
    .navigationTitle("Profile")
    .alert(isPresented: $showAlert) {
      Alert(title: Text("Alert!"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
        if isDeletingAccount {
          presentationMode.wrappedValue.dismiss()
        }
      })
    }
    .alert(isPresented: $showConfirmationAlert) {
      Alert(
        title: Text("Confirm Deletion"),
        message: Text("Are you sure you want to delete your account? This action cannot be undone."),
        primaryButton: .destructive(Text("Delete")) { deleteAccount() },
        secondaryButton: .cancel()
      )
    }
  }
  
  // Firebase logout method
  func logoutUser() {
    do {
      try Auth.auth().signOut()
      presentationMode.wrappedValue.dismiss()
      print("User logged out successfully!")
    } catch let signOutError as NSError {
      alertMessage = "Error signing out: \(signOutError.localizedDescription)"
      showAlert = true
    }
    isLoggingOut = false
  }
  
  // Delete user account
  private func deleteAccount() {
    guard let user = Auth.auth().currentUser else {
      alertMessage = "No user is currently logged in."
      showAlert = true
      isDeletingAccount = false
      return
    }

    user.delete { error in
      if let error = error {
        alertMessage = "Error deleting account: \(error.localizedDescription)"
        showAlert = true
      } else {
        alertMessage = "Account deleted successfully!"
        showAlert = true
      }
      isDeletingAccount = false
    }
  }
}

struct ProfileView_Previews: PreviewProvider {
  static var previews: some View {
    ProfileView()
  }
}
