//
//  ThemeProcessingView.swift
//  AiLens3
//
//  Created by Jessy  Martinez  on 4/12/25.
//

import SwiftUI

struct ThemeProcessingView: View {
    let originalImage: UIImage
    let theme: String
    @StateObject private var viewModel = ImageThemeViewModel()
    @State private var navigateBack = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            if viewModel.isProcessing {
                loadingView
            } else if let processedImage = viewModel.processedImage {
                resultView(image: processedImage)
            } else {
                originalImageView
            }
        }
        .navigationTitle("Theme: \(theme)")
        .navigationBarBackButtonHidden(viewModel.isProcessing)
        .onAppear {
            viewModel.applyTheme(to: originalImage, theme: theme)
        }
        .navigationDestination(isPresented: $navigateBack) {
            ThemeSelectionView()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(2.0)
            Text("Converting to \(theme) style...")
                .font(.headline)
            Text("This may take a minute...")
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
        }
        .padding()
    }
    
    private var originalImageView: some View {
        VStack {
            Image(uiImage: originalImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
            
            Text("Starting conversion to \(theme) style...")
                .font(.headline)
                .padding()
        }
    }
    
    private func resultView(image: UIImage) -> some View {
        VStack {
            Text("Transformation complete!")
                .font(.headline)
                .padding(.top)
            
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
            
            HStack {
                Button(action: {
                    // Create a new photo with a different theme
                    navigateBack = true
                }) {
                    Text("New Photo")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(AppTheme.secondary)
                        .cornerRadius(10)
                }
                
                Spacer()
                
                Button(action: {
                    // Save to Photos
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    
                    // Show a save confirmation
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    // Simple animation for feedback
                    withAnimation {
                        // You could add more feedback here
                    }
                }) {
                    Text("Save to Photos")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(AppTheme.primary)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}
