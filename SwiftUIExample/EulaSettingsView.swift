// EulaSettingsView.swift
// Item Spotter
//
// Created by Hamilton Center on 9/19/24.

import SwiftUI

struct EulaSettingsView: View {
    private var eulaSections: [(title: String, content: String)] = [
        ("1. Introduction", """
            This End User License Agreement ("Agreement") is a legal agreement between you ("User") and Hamilton Center ("Developer"). By downloading, installing, or using the Item Spotter app ("App"), you agree to be bound by the terms of this Agreement and the app's Terms of Service.
            """),
        ("2. License Grant", """
            The Developer grants you a limited, non-exclusive, non-transferable license to use the App on your mobile device, subject to the terms of this Agreement.
            """),
        ("3. User-Generated Content Policy", """
            The App allows users to post content regarding lost and found items. The Developer has a strict zero-tolerance policy for objectionable content and abusive behavior. This includes, but is not limited to, any content that is:
            - Abusive
            - Defamatory
            - Obscene
            - Harassing
            - Threatening
            - Infringing on the rights of others
            
            By using the App, you agree not to post any content that violates this policy. The Developer reserves the right to review, monitor, and remove any content that violates these terms at their sole discretion.
            """),
        ("4. Acceptance of Terms", """
            By using the App, you confirm that you have read, understood, and agreed to this Agreement, including the zero-tolerance policy for objectionable content and abusive users. You also acknowledge that by accepting this Agreement, you are accepting the Terms of Service for the App.
            """),
        ("5. User Responsibilities", """
            You are solely responsible for your use of the App and any content you post. You must comply with all applicable laws and regulations in connection with your use of the App.
            """),
        ("6. Limitation of Liability", """
            The Developer is not liable for any direct, indirect, incidental, or consequential damages resulting from the use or inability to use the App, even if the Developer has been advised of the possibility of such damages.
            """),
        ("7. Contact Information", """
            If you have any questions regarding this Agreement, please contact:
            Hamilton Center
            Email: hamiltonncenter@gmail.com
            Telephone: 205-718-1377
            State: AL
            Country: United States
            """),
        ("8. Governing Law", """
            This Agreement shall be governed by the laws of the State of Alabama, United States.
            """),
        ("9. Changes to This Agreement", """
            The Developer reserves the right to modify this Agreement at any time. Changes will be effective immediately upon posting the revised Agreement within the App. Your continued use of the App after any changes constitutes your acceptance of the new terms.
            """)
    ]

    @State private var isTermsExpanded = false

    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(eulaSections, id: \.title) { section in
                        SectionView(title: section.title, content: section.content)
                    }
                    
                    // Terms of Service Section
                    HStack {
                        Button(action: {
                            withAnimation {
                                isTermsExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Text("View Terms of Service")
                                    .font(.headline)
                                Image(systemName: isTermsExpanded ? "chevron.up" : "chevron.down")
                            }
                        }
                        .padding()
                        .foregroundColor(.blue)
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(8)
                    }
                    
                    if isTermsExpanded {
                        NavigationLink(destination: TermsView()) {
                            Text("Go to Terms of Service")
                                .foregroundColor(.blue)
                                .underline()
                        }
                        .padding(.leading, 20)
                    }

                    Text("End of Agreement")
                        .font(.subheadline)
                        .italic()
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
        .navigationTitle("End User License Agreement")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.white)
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct EulaSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EulaSettingsView()
        }
    }
}
