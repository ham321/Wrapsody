//  FAQView.swift
//  Lost and Found
//
//  Created by Hamilton Center on 9/14/24.
//

import SwiftUI

// Sample FAQ Data
struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

let sampleFAQs = [
    FAQItem(question: "How do I contact support?", answer: "To contact support you can email us at, Hamiltonncenter@gmail.com for any questions or concerns")
    // Add more FAQ items as needed
]



struct FAQView: View {
    let faqs: [FAQItem]

    var body: some View {
        List(faqs) { faq in
            VStack(alignment: .leading) {
                Text(faq.question)
                    .font(.headline)
                Text(faq.answer)
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .navigationTitle("Help & FAQ")
    }
}

struct FAQView_Previews: PreviewProvider {
    static var previews: some View {
        FAQView(faqs: sampleFAQs)
    }
}
