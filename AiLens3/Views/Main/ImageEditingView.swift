//
//  ImageEditingView.swift
//  AiLens3
//
//  Created by Jessy  Martinez  on 4/12/25.
//

import SwiftUI
import PhotosUI

struct ImageEditingView: View {
    @StateObject private var viewModel = ImageEditingViewModel()
    @State private var showingImagePicker = false
    @State private var showingSavedConfirmation = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isEditing {
                    loadingView
                } else if viewModel.editedImage != nil {
                    editedImageView
                } else if viewModel.selectedImage != nil {
                    selectedImageView
                } else {
                    placeholderView
                }
                
                promptInputView
            }
            .padding()
            .navigationTitle("AiLens")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.resetImages()
                    }) {
                        Text("Reset")
                            .foregroundColor(viewModel.selectedImage == nil ? .gray : .blue)
                    }
                    .disabled(viewModel.selectedImage == nil)
                }
            }
            .alert(isPresented: $viewModel.showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage ?? "An unknown error occurred."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Component Views
    
    private var placeholderView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "photo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.gray.opacity(0.5))
            
            Text("Tap to select an image")
                .font(.headline)
                .foregroundColor(.gray)
            
            Spacer()
            
            Button(action: {
                showingImagePicker = true
            }) {
                Text("Select Image")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primary)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $viewModel.selectedImage)
            }
        }
    }
    
    private var selectedImageView: some View {
        VStack {
            if let image = viewModel.selectedImage {
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
            }
            
            HStack {
                Button(action: {
                    showingImagePicker = true
                }) {
                    Text("Change Image")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(AppTheme.secondary)
                        .cornerRadius(10)
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(image: $viewModel.selectedImage)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.editImage()
                }) {
                    Text("Apply AI Edit")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(viewModel.prompt.isEmpty ? Color.gray : AppTheme.primary)
                        .cornerRadius(10)
                }
                .disabled(viewModel.prompt.isEmpty)
            }
        }
    }
    
    private var editedImageView: some View {
        VStack {
            if let image = viewModel.editedImage {
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
            }
            
            HStack {
                Button(action: {
                    // Go back to original image
                    viewModel.editedImage = nil
                }) {
                    Text("Original")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(AppTheme.secondary)
                        .cornerRadius(10)
                }
                
                Spacer()
                
                Button(action: {
                    if let image = viewModel.editedImage {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        showingSavedConfirmation = true
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
        }
        .overlay(
            Group {
                if showingSavedConfirmation {
                    VStack {
                        Text("Image saved!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(AppTheme.secondary)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .transition(.move(edge: .top))
                    .animation(.spring(), value: showingSavedConfirmation)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showingSavedConfirmation = false
                            }
                        }
                    }
                }
            }
            .padding(.top, 50),
            alignment: .top
        )
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .scaleEffect(2.0)
                .padding()
            
            Text(viewModel.progress)
                .font(.headline)
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
    
    private var promptInputView: some View {
        VStack(alignment: .leading) {
            Text("Prompt:")
                .font(.headline)
                .padding(.top)
            
            ZStack(alignment: .topLeading) {
                if viewModel.prompt.isEmpty {
                    Text("Describe the edits you want to make...")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                
                TextEditor(text: $viewModel.prompt)
                    .frame(minHeight: 80)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.secondary.opacity(0.5))
                    )
                    .opacity(viewModel.prompt.isEmpty ? 0.85 : 1)
            }
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let error = error {
                        print("Error loading image: \(error.localizedDescription)")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

// MARK: - App Theme
struct AppTheme {
    static let primary = Color.blue
    static let secondary = Color.purple
    static let background = Color.white
    static let text = Color.black
}

// MARK: - Preview
struct ImageEditingView_Previews: PreviewProvider {
    static var previews: some View {
        ImageEditingView()
    }
}
