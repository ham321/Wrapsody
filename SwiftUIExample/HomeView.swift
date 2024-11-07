// HomeView.swift
// Lost and Found
//
// Created by Hamilton Center on 8/16/24.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
            Text("Hello, World!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all)) // Background color covers full screen
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
