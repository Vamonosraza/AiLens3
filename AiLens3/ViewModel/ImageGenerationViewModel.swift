//
//  ImageGenerationViewModel.swift
//  AiLens3
//
//  Created by Jessy  Martinez  on 4/12/25.
//

import Foundation
import SwiftUI
import Combine

class ImageGenerationViewModel: ObservableObject {
    private let openAIService = OpenAIService()
    
    @Published var prompt: String = ""
    @Published var generatedImage: UIImage?
    @Published var isGenerating: Bool = false
    @Published var progress: String = ""
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    func generateImage() {
        guard !prompt.isEmpty else {
            errorMessage = "Please enter a prompt"
            showError = true
            return
        }
        
        isGenerating = true
        progress = "Preparing request..."
        
        Task {
            do {
                let startTime = Date()
                progress = "Contacting OpenAI..."
                
                let image = try await openAIService.generateImage(prompt: prompt)
                
                let duration = Date().timeIntervalSince(startTime)
                
                await MainActor.run {
                    progress = "Image generated in \(String(format: "%.1f", duration)) seconds"
                    generatedImage = image
                    isGenerating = false
                }
                
            } catch {
                print("Error: \(error)")
                await MainActor.run {
                    errorMessage = "Error: \(error.localizedDescription)"
                    showError = true
                    isGenerating = false
                }
            }
        }
    }
    
    func resetImage() {
        generatedImage = nil
        prompt = ""
    }
}
