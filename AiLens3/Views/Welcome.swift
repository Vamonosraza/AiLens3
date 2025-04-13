//
//  Welcome.swift
//  AiLens3
//
//  Created by Jessy  Martinez  on 4/12/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var showMainApp = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.accent
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // App logo/icon
                    Image(systemName: "camera.aperture")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .foregroundColor(AppTheme.primary)
                        .padding(.bottom, 20)
                    
                    // App name
                    Text("AiLens3")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.primary)
                    
                    Text("AI-Powered Image Editing")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.secondary)
                        .padding(.top, 5)
                    
                    Spacer()
                    
                    // Start button
                    NavigationLink(destination: ThemeSelectionView()) {
                        Text("Start")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.primary)
                            .cornerRadius(10)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 50)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
