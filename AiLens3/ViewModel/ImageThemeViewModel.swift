//
//  ImageThemeViewModel.swift
//  AiLens3
//
//  Created by Jessy  Martinez  on 4/12/25.
//

import Foundation
import UIKit
import SwiftUI

class ImageThemeViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var processedImage: UIImage?
    @Published var errorMessage: String?
    
    private let openAIService = OpenAIService()
    
    func applyTheme(to image: UIImage, theme: String) {
        isProcessing = true
        
        // Construct prompt based on theme
        let prompt: String
        switch theme {
        case "Studio Ghibli":
            prompt = "Transform this image into Studio Ghibli animation style, with dreamlike landscapes, whimsical characters, and vibrant natural colors."
        case "Water Color":
            prompt = "Convert this image into a beautiful watercolor painting, with soft edges, flowing colors, and artistic brush strokes."
        case "CyberPunk":
            prompt = "Transform this image into a cyberpunk style with neon lights, tech elements, dystopian urban setting, and vibrant contrasting colors."
        default:
            prompt = "Transform this image into an artistic \(theme) style."
        }
        
        Task {
            do {
                // Call OpenAI to edit the image
                let result = try await openAIService.editImage(
                    originalImage: image,
                    prompt: prompt
                )
                
                // Update UI on main thread
                await MainActor.run {
                    self.processedImage = result
                    self.isProcessing = false
                }
                
            } catch {
                print("Error: \(error)")
                
                // Handle errors on main thread
                await MainActor.run {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
}
