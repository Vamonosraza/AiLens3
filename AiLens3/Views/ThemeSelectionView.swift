//
//  ThemeSelectionView.swift
//  AiLens3
//
//  Created by Jessy  Martinez  on 4/12/25.
//

import SwiftUI

struct ThemeSelectionView: View {
    @State private var selectedTheme: String?
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var navigateToEditing = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                Text("Select a Theme")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textColor)
                    .padding(.top, 30)
                
                Spacer()
                
                // Studio Ghibli Theme Button
                ThemeButton(
                    title: "Studio Ghibli",
                    description: "Magical, whimsical anime style",
                    iconName: "cloud.sun.fill",
                    color: Color(red: 0.4, green: 0.7, blue: 0.9)
                ) {
                    selectedTheme = "Studio Ghibli"
                    showCamera = true
                }
                
                // Watercolor Theme Button
                ThemeButton(
                    title: "Water Color",
                    description: "Soft, flowing artistic style",
                    iconName: "drop.fill",
                    color: Color(red: 0.8, green: 0.6, blue: 0.9)
                ) {
                    selectedTheme = "Water Color"
                    showCamera = true
                }
                
                // Cyberpunk Theme Button
                ThemeButton(
                    title: "CyberPunk",
                    description: "Futuristic, neon tech aesthetic",
                    iconName: "bolt.fill",
                    color: Color(red: 0.9, green: 0.4, blue: 0.7)
                ) {
                    selectedTheme = "CyberPunk"
                    showCamera = true
                }
                
                Spacer()
            }
            .padding()
            .background(AppTheme.primary)
            .sheet(isPresented: $showCamera) {
                CameraView(image: $capturedImage, isShown: $showCamera, onImageCaptured: {
                    navigateToEditing = true
                })
            }
            .navigationDestination(isPresented: $navigateToEditing) {
                if let image = capturedImage, let theme = selectedTheme {
                    ThemeProcessingView(originalImage: image, theme: theme)
                }
            }
            .navigationTitle("AiLens3")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Custom theme button component
struct ThemeButton: View {
    let title: String
    let description: String
    let iconName: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(color)
                    .cornerRadius(15)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(AppTheme.textColor)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(color)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

struct ThemeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeSelectionView()
    }
}
