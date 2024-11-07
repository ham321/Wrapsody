import SwiftUI

struct TermsView: View {
    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
              VStack(alignment: .leading, spacing: 20) {
                Text("""
                      These Terms of Use ("Terms") govern your use of the Item Spotter app. By accepting the End User License Agreement (EULA), you also agree to these Terms. If you do not agree to these Terms and the EULA, you should not use the app.
                      """)
                .font(.body)
                .padding(.bottom, 15)
                .multilineTextAlignment(.leading)
                
                SectionView(title: "1. Introduction", content: """
                      This agreement outlines your rights and responsibilities while using the Item Spotter app.
                      """)
                
                SectionView(title: "2. Definitions", content: """
                      - **User**: Any individual who accesses or uses the app.
                      - **Content**: Any material, including text, images, and comments submitted by users.
                      """)
                
                SectionView(title: "3. User Accounts", content: """
                      - You must provide accurate and complete information when creating an account.
                      - You are responsible for safeguarding your account and password.
                      """)
                
                SectionView(title: "4. License Grant", content: """
                      - We grant you a limited, non-exclusive, non-transferable license to use the app for personal, non-commercial purposes.
                      """)
                
                SectionView(title: "5. User Conduct", content: """
                      - You agree to adhere to a zero-tolerance policy for discriminatory, abusive, harassing, or otherwise objectionable behavior.
                      - Any form of harassment, threats, or discrimination is strictly prohibited and may result in immediate suspension or termination of your account.
                      - Your interactions must be respectful and in compliance with our community standards.
                      """)
                
                SectionView(title: "6. Content Submission", content: """
                      - You retain ownership of your content but grant us a license to use, display, and distribute it.
                      - You are responsible for ensuring your content does not infringe on the rights of others and complies with our guidelines.
                      """)
                
                SectionView(title: "7. Intellectual Property", content: """
                      - All intellectual property rights in the app and its content are owned by us or our licensors.
                      """)
                
                SectionView(title: "8. Privacy Policy", content: """
                      - Our privacy policy governs how we collect, use, and protect your data. [Link to Privacy Policy]
                      """)
                
                SectionView(title: "9. Dispute Resolution", content: """
                      - Any disputes will be resolved through arbitration in accordance with [Arbitration Rules].
                      """)
                
                SectionView(title: "10. Limitation of Liability", content: """
                      - We are not liable for any damages arising from your use of the app, to the extent permitted by law.
                      """)
                
                SectionView(title: "11. Indemnification", content: """
                      - You agree to indemnify us from any claims arising out of your use of the app or violation of these Terms.
                      """)
                
                SectionView(title: "12. Governing Law", content: """
                      - These Terms are governed by the laws of [Your Jurisdiction].
                      """)
                
                SectionView(title: "13. Termination", content: """
                      - We may terminate or suspend your access if you violate these Terms or engage in unacceptable behavior.
                      """)
                
                SectionView(title: "14. Changes to Terms", content: """
                      - We may update these Terms and will notify you of significant changes. Continued use after changes signifies acceptance.
                      """)
                
                SectionView(title: "15. Contact Information", content: """
                      - For questions or concerns, contact us at hamiltonncenter@gmail.com.
                      """)
                
                Text("By accepting the EULA, you also acknowledge that you have read and agreed to these Terms of Use.")
                  .font(.subheadline)
                  .italic()
                  .padding(.top, 10)
                  .multilineTextAlignment(.leading)
                
                Text("Thank you for being part of the Item Spotter community!")
                  .font(.body)
                  .padding(.top, 10)
                  .multilineTextAlignment(.leading)
              }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.4), radius: 6, x: 0, y: 4)
                .padding(.horizontal)
            }
            .frame(maxHeight: .infinity)

            Spacer()
        }
        .padding()
        .navigationBarTitle("Terms of Use", displayMode: .inline)
        .background(Color.white)
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct SectionView: View {
    var title: String
    var content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.bottom, 5)
            
            Text(content)
                .font(.body)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 20)
        }
    }
}

struct TermsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TermsView()
        }
    }
}
