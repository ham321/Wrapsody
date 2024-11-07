// SettingsView.swift
// Item Spotter
//
// Created by Hamilton Center on 9/13/24.

import SwiftUI

struct SettingsView: View {
    var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return "Unknown"
    }
    
    var body: some View {
        VStack {
            List {
                // NavigationLink for Update Password
                NavigationLink(destination: UpdatePasswordView()) {
                    Label("Update Password", systemImage: "lock.fill")
                        .foregroundColor(.black)
                }
              
              // NavigationLink for Terms of Use
              NavigationLink(destination: OrderHistoryView()) {
                  Label("Order History", systemImage: "bookmark.fill")
                      .foregroundColor(.black)
              }
                
                // NavigationLink for Help & FAQ
                NavigationLink(destination: FAQView(faqs: sampleFAQs)) {
                    Label("Help & FAQ", systemImage: "questionmark.circle.fill")
                        .foregroundColor(.black)
                }

                // NavigationLink for Terms of Use
                NavigationLink(destination: TermsView()) {
                    Label("Terms of Use", systemImage: "doc.text.fill")
                        .foregroundColor(.black)
                }
                
                // NavigationLink for End User License Agreement
                NavigationLink(destination: EulaSettingsView()) {
                    Label("End User License Agreement", systemImage: "doc.text")
                        .foregroundColor(.black)
                }
            }
            .listStyle(PlainListStyle())

            Text("Version \(appVersion)")
                .foregroundColor(.gray)
                .font(.footnote)
                .padding(.bottom, 10)
        }
        .navigationTitle("Settings")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
}
