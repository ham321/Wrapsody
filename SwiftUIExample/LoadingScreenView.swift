//
//  LoadingScreenView.swift
//  Lost and Found
//
//  Created by Hamilton Center on 8/16/24.
//

import SwiftUI

struct LoadingScreenView: View {
    var body: some View {
        ZStack {
            // Background gradient with emerald green and yellow
          LinearGradient(gradient: Gradient(colors: [Color.wrapsodyBlue, Color.wrapsodyGold]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack {
                Text("Loading...")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .scaleEffect(2)
            }
        }
    }
}

struct LoadingScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingScreenView()
    }
}


