//
//  UpdatePasswordView.swift
//  Lost and Found
//
//  Created by Hamilton Center on 9/14/24.
//

import SwiftUI
import FirebaseAuth

struct UpdatePasswordView: View {
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String = ""
    @State private var isPasswordUpdated: Bool = false

    var body: some View {
        VStack {
            Text("Update Password")
                .font(.largeTitle)
                .padding()

            SecureField("Current Password", text: $currentPassword)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5.0)
                .padding(.bottom, 20)

            SecureField("New Password", text: $newPassword)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5.0)
                .padding(.bottom, 20)

            SecureField("Confirm New Password", text: $confirmPassword)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5.0)
                .padding(.bottom, 20)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.bottom, 20)
            }

            if isPasswordUpdated {
                Text("Password updated successfully!")
                    .foregroundColor(.green)
                    .padding(.bottom, 20)
            }

            Button(action: {
                updatePassword()
            }) {
                Text("Update Password")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }

    private func updatePassword() {
        guard validatePasswords() else { return }
        
        reauthenticateUser(currentPassword: currentPassword) { success in
            if success {
                Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
                    if let error = error {
                        errorMessage = "Failed to update password: \(error.localizedDescription)"
                    } else {
                        isPasswordUpdated = true
                        errorMessage = ""
                    }
                }
            } else {
                errorMessage = "Current password is incorrect."
            }
        }
    }

    private func validatePasswords() -> Bool {
        if newPassword != confirmPassword {
            errorMessage = "New password and confirmation do not match."
            return false
        }
        if newPassword.count < 6 {
            errorMessage = "Password must be at least 6 characters long."
            return false
        }
        return true
    }

    private func reauthenticateUser(currentPassword: String, completion: @escaping (Bool) -> Void) {
        let user = Auth.auth().currentUser
        if let email = user?.email {
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)

            user?.reauthenticate(with: credential, completion: { result, error in
                if let error = error {
                    print("Reauthentication failed: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            })
        }
    }
}
