//
//  OpenAIService.swift
//  AiLens3
//
//  Created by Jessy  Martinez  on 4/12/25.
//

import Foundation
import UIKit

class OpenAIService {
    private let apiKey = APIConfiguration.openAIKey
    
    // MARK: - Response and Error Models
    
    struct OpenAIImageResponse: Codable {
        let created: Int
        let data: [ImageData]
        
        struct ImageData: Codable {
            let url: String
        }
    }
    
    struct ErrorResponse: Codable {
        let error: APIError
        
        struct APIError: Codable {
            let message: String
            let type: String?
            let param: String?
            let code: String?
        }
    }
    
    enum APIError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case httpError(statusCode: Int)
        case serverError(message: String)
        case invalidImageURL
        case invalidImageData
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .invalidResponse:
                return "Invalid response from server"
            case .httpError(let statusCode):
                return "HTTP error: \(statusCode)"
            case .serverError(let message):
                return message
            case .invalidImageURL:
                return "Invalid image URL in response"
            case .invalidImageData:
                return "Could not create image from data"
            case .unknown:
                return "Unknown error occurred"
            }
        }
    }
    
    // MARK: - Main Methods
    
    func editImage(originalImage: UIImage, prompt: String, mask: UIImage? = nil) async throws -> UIImage {
        // Convert image to PNG with transparency (required by OpenAI API)
        guard let pngData = convertToPngWithTransparency(image: originalImage) else {
            throw APIError.invalidImageData
        }
        
        // Setup multipart form data
        let boundary = UUID().uuidString
        let bodyData = createMultipartFormData(
            boundary: boundary,
            imageData: pngData,
            prompt: prompt,
            maskData: mask != nil ? convertToPngWithTransparency(image: mask!) : nil
        )
        
        // Create URL request
        guard let url = URL(string: "https://api.openai.com/v1/images/edits") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        
        // Configure session with extended timeouts
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0
        config.timeoutIntervalForResource = 90.0
        config.waitsForConnectivity = true
        config.httpMaximumConnectionsPerHost = 1
        
        let session = URLSession(configuration: config)
        
        // Implement retry logic
        let maxAttempts = 3
        var attempts = 0
        var lastError: Error? = nil
        
        while attempts < maxAttempts {
            attempts += 1
            
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if httpResponse.statusCode != 200 {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw APIError.serverError(message: errorResponse.error.message)
                    } else {
                        throw APIError.httpError(statusCode: httpResponse.statusCode)
                    }
                }
                
                // Parse response to get image URL
                let decoder = JSONDecoder()
                let urlResponse = try decoder.decode(OpenAIImageResponse.self, from: data)
                
                // Download the actual image from the URL
                guard let imageURL = URL(string: urlResponse.data[0].url) else {
                    throw APIError.invalidImageURL
                }
                
                let (imageData, _) = try await session.data(from: imageURL)
                
                guard let image = UIImage(data: imageData) else {
                    throw APIError.invalidImageData
                }
                
                return image
                
            } catch {
                lastError = error
                
                if attempts < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(attempts * 2 * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? APIError.unknown
    }
    
    func generateImage(prompt: String, size: String = "1024x1024", n: Int = 1) async throws -> UIImage {
        // Create URL request
        guard let url = URL(string: "https://api.openai.com/v1/images/generations") else {
            throw APIError.invalidURL
        }
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "model": "dall-e-3", // Using DALL-E 3 for best quality
            "prompt": prompt,
            "n": n,
            "size": size,
            "response_format": "url"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        // Configure session with extended timeouts
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0
        config.timeoutIntervalForResource = 90.0
        
        let session = URLSession(configuration: config)
        
        // Implement retry logic
        let maxAttempts = 3
        var attempts = 0
        var lastError: Error? = nil
        
        while attempts < maxAttempts {
            attempts += 1
            
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if httpResponse.statusCode != 200 {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw APIError.serverError(message: errorResponse.error.message)
                    } else {
                        throw APIError.httpError(statusCode: httpResponse.statusCode)
                    }
                }
                
                // Parse response to get image URL
                let decoder = JSONDecoder()
                let urlResponse = try decoder.decode(OpenAIImageResponse.self, from: data)
                
                // Download the actual image from the URL
                guard let imageURL = URL(string: urlResponse.data[0].url) else {
                    throw APIError.invalidImageURL
                }
                
                let (imageData, _) = try await session.data(from: imageURL)
                
                guard let image = UIImage(data: imageData) else {
                    throw APIError.invalidImageData
                }
                
                return image
                
            } catch {
                lastError = error
                
                if attempts < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(attempts * 2 * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? APIError.unknown
    }
    // MARK: - Helper Methods
    
    private func convertToPngWithTransparency(image: UIImage) -> Data? {
        // If the image already has an alpha channel, just convert to PNG
        if let pngData = image.pngData() {
            return pngData
        }
        
        // Otherwise, we'll need to create a new image with transparency
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        image.draw(at: CGPoint.zero)
        let imageWithAlpha = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return imageWithAlpha?.pngData()
    }
    
    private func createMultipartFormData(boundary: String, imageData: Data, prompt: String, maskData: Data? = nil) -> Data {
        var body = Data()
        
        // Add image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add mask if available
        if let maskData = maskData {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"mask\"; filename=\"mask.png\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
            body.append(maskData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // Add prompt
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        body.append(prompt.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("dall-e-2".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add response format - URL for better compatibility
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("url".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add size
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"size\"\r\n\r\n".data(using: .utf8)!)
        body.append("512x512".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
}
