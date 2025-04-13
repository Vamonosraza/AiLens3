//
//  CameraView.swift
//  AiLens3
//
//  Created by Jessy  Martinez  on 4/12/25.
//

import SwiftUI
import UIKit

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isShown: Bool
    var onImageCaptured: () -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // Process the image (convert to PNG and compress if needed)
                parent.image = processImage(image)
                parent.onImageCaptured()
            }
            parent.isShown = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isShown = false
        }
        
        // Process image to PNG under 4MB with alpha channel
        private func processImage(_ image: UIImage) -> UIImage {
            // Step 1: Create a new image with alpha channel
            let imageWithAlpha = addAlphaChannelIfNeeded(image)
            
            // Step 2: Resize image if needed
            var processedImage = imageWithAlpha
            let maxFileSize = 4 * 1024 * 1024 // 4MB
            
            // Step 3: Adjust dimensions if needed
            let maxDimension: CGFloat = 1024 // Reduced for better performance with OpenAI API
            if imageWithAlpha.size.width > maxDimension || imageWithAlpha.size.height > maxDimension {
                let scale = maxDimension / max(imageWithAlpha.size.width, imageWithAlpha.size.height)
                let newWidth = imageWithAlpha.size.width * scale
                let newHeight = imageWithAlpha.size.height * scale
                let newSize = CGSize(width: newWidth, height: newHeight)
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0) // false = with alpha channel
                imageWithAlpha.draw(in: CGRect(origin: .zero, size: newSize))
                if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
                    processedImage = resizedImage
                }
                UIGraphicsEndImageContext()
            }
            
            // Step 4: Check file size and compress if needed
            guard let imageData = processedImage.pngData() else { return processedImage }
            print("Original PNG size: \(imageData.count) bytes")
            
            if imageData.count > maxFileSize {
                // Reduce quality to ensure size is under 4MB
                var compression: CGFloat = 0.8
                var compressedData = processedImage.jpegData(compressionQuality: compression)
                
                // Keep reducing quality until we're under the limit
                while let data = compressedData, data.count > maxFileSize && compression > 0.1 {
                    compression -= 0.1
                    compressedData = processedImage.jpegData(compressionQuality: compression)
                }
                
                if let finalData = compressedData, let compressedImage = UIImage(data: finalData) {
                    // Convert back to PNG with alpha
                    processedImage = addAlphaChannelIfNeeded(compressedImage)
                    print("Compressed size: \(finalData.count) bytes")
                }
            }
            
            return processedImage
        
        }
        private func addAlphaChannelIfNeeded(_ image: UIImage) -> UIImage {
            // Check if the image already has an alpha channel
            guard let cgImage = image.cgImage else { return image }
            
            // If it already has an alpha channel, return the original
            if cgImage.alphaInfo != .none && cgImage.alphaInfo != .noneSkipLast && cgImage.alphaInfo != .noneSkipFirst {
                return image
            }
            
            // Create a new image with alpha channel
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            image.draw(at: .zero)
            let imageWithAlpha = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return imageWithAlpha ?? image
        }
    }
}
