import Foundation
import SwiftUI

struct EulaView: View {
    @Binding var hasAcceptedEula: Bool
    @State private var hasAgreed: Bool = false // Checkbox state
    var onAccept: () -> Void // Closure to handle acceptance

    var body: some View {
        VStack(spacing: 15) {
            Text("End User License Agreement (EULA)")
                .font(.title2)
                .bold()
                .padding(.top)

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text(eulaText)
                        .font(.body)
                        .padding()

                    Text("End of Agreement")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity) // Make width flexible
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 1)
                )
            }
            .frame(maxHeight: 400) // Adjusted height of the scrollable area

            // Checkbox for agreement
            Toggle(isOn: $hasAgreed) {
                Text("I have read and agree to the terms of the End User License Agreement")
                    .font(.subheadline)
            }
            .padding(.horizontal)
            .padding(.top, 5)

            // Button to agree to terms
            Button(action: {
                hasAcceptedEula = true // Accept EULA
                onAccept() // Call the onAccept closure
            }) {
                Text("Agree to Terms and Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(hasAgreed ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .shadow(color: hasAgreed ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .disabled(!hasAgreed) // Disable if not agreed
            .padding(.horizontal)

            // Navigation link to Terms of Service
            NavigationLink(destination: TermsView()
                .frame(maxHeight: .infinity) // Limit height to approximately half of EULA height
            ) {
                Text("View Terms of Service")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                    .padding(8)
                    .frame(maxWidth: 200)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                    .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .padding(.top, 5)
        }
        .padding()
        .navigationBarBackButtonHidden(false) // Show the back button
    }

  var eulaText: String {
      """
      End User License Agreement (EULA)

      Effective Date: September 20, 2024

      1. **Introduction**
      This End User License Agreement ("Agreement") is a legal agreement between you ("User") and Hamilton Center ("Developer"). By downloading, installing, or using the Item Spotter app ("App"), you agree to be bound by the terms of this Agreement and the app's Terms of Service.

      2. **License Grant**
      The Developer grants you a limited, non-exclusive, non-transferable license to use the App on your mobile device, subject to the terms of this Agreement.

      3. **User-Generated Content Policy**
      The App allows users to post content regarding lost and found items. The Developer has a strict zero-tolerance policy for objectionable content and abusive behavior. This includes, but is not limited to, any content that is:
      - Abusive
      - Defamatory
      - Obscene
      - Harassing
      - Threatening
      - Infringing on the rights of others

      By using the App, you agree not to post any content that violates this policy. The Developer reserves the right to review, monitor, and remove any content that violates these terms at their sole discretion.

      4. **Acceptance of Terms**
      By using the App, you confirm that you have read, understood, and agreed to this Agreement, including the zero-tolerance policy for objectionable content and abusive users. You also acknowledge that by accepting this Agreement, you are accepting the Terms of Service for the App.

      5. **User Responsibilities**
      You are solely responsible for your use of the App and any content you post. You must comply with all applicable laws and regulations in connection with your use of the App.

      6. **Limitation of Liability**
      The Developer is not liable for any direct, indirect, incidental, or consequential damages resulting from the use or inability to use the App, even if the Developer has been advised of the possibility of such damages.

      7. **Contact Information**
      If you have any questions regarding this Agreement, please contact:
      Hamilton Center
      Email: hamiltonncenter@gmail.com
      Telephone: 205-718-1377
      State: AL
      Country: United States

      8. **Governing Law**
      This Agreement shall be governed by the laws of the State of Alabama, United States.

      9. **Changes to This Agreement**
      The Developer reserves the right to modify this Agreement at any time. Changes will be effective immediately upon posting the revised Agreement within the App. Your continued use of the App after any changes constitutes your acceptance of the new terms.
      """
  }




}

struct EulaView_Previews: PreviewProvider {
    static var previews: some View {
        EulaView(hasAcceptedEula: .constant(false), onAccept: {})
    }
}
