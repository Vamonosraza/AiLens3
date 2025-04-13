//
//  ImageEditingViewModel.swift
//  AiLens3
//
//  Created by Jessy  Martinez  on 4/12/25.
//

import SwiftUI
import Combine
import PhotosUI

class ImageEditingViewModel: ObservableObject {
    private let openAIService = OpenAIService()
    
    @Published var selectedImage: UIImage?
    @Published var editedImage: UIImage?
    @Published var prompt: String = ""
    @Published var isEditing: Bool = false
    @Published var progress: String = ""
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    func editImage() {
        guard let originalImage = selectedImage, !prompt.isEmpty else {
            errorMessage = prompt.isEmpty ? "Please enter a prompt" : "Please select an image"
            showError = true
            return
        }
        
        isEditing = true
        progress = "Preparing your image..."
        
        Task {
            do {
                let startTime = Date()
                
                // Update progress on main thread
                await MainActor.run {
                    progress = "Applying AI edits..."
                }
                
                // Call the OpenAI service to edit the image
                let result = try await openAIService.editImage(
                    originalImage: originalImage,
                    prompt: prompt
                )
                
                let duration = Date().timeIntervalSince(startTime)
                
                // Update UI on main thread
                await MainActor.run {
                    progress = "Image edited in \(String(format: "%.1f", duration)) seconds"
                    editedImage = result
                    isEditing = false
                }
                
            } catch {
                print("Error: \(error)")
                
                // Handle errors on main thread
                await MainActor.run {
                    errorMessage = "Error: \(error.localizedDescription)"
                    showError = true
                    isEditing = false
                }
            }
        }
    }
    
    func resetImages() {
        selectedImage = nil
        editedImage = nil
        prompt = ""
    }
}
