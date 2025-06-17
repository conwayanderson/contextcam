//
//  AIImageCaptureController.swift
//  context-camera
//
//  Smart camera controller for AI image analysis
//  Handles capture, optimization, and encoding for any AI vision API
//

import AVFoundation
import UIKit
import Foundation

/// Manages camera capture and image optimization for AI analysis services
class AIImageCaptureController: ObservableObject {
    @Published var cameraController: CameraController?
    @Published var captureState: CaptureState = .idle
    @Published var processingState: ProcessingState = .ready
    @Published var isAnalysisPending: Bool = false
    
    private var automaticCaptureTimer: Timer?
    private let configuration = ImageAnalysisConfiguration.optimizedForAI
    
    // MARK: - State Management
    
    /// States representing the camera capture process
    enum CaptureState {
        case idle               // Not actively capturing
        case preparingCapture   // Setting up for capture
        case capturing          // Taking snapshot
        case captured           // Image successfully captured
    }
    
    /// States representing image processing for AI analysis
    enum ProcessingState {
        case ready              // Ready to process images
        case optimizingImage    // Resizing and compressing
        case encodingForAPI     // Converting to API format
        case complete           // Processing finished
        case failed(Error)     // Processing error occurred
    }
    
    /// Configuration for AI-optimized image capture and processing
    struct ImageAnalysisConfiguration {
        let captureInterval: TimeInterval = 1.5
        let maxImageDimension: CGFloat = 320
        let compressionQuality: CGFloat = 0.5
        let shouldLogMetrics: Bool = true
        
        static let optimizedForAI = ImageAnalysisConfiguration()
    }

    init() {
        // Initialize camera controller for AI image analysis
        let cameraController = CameraController()
        self.cameraController = cameraController
    }
    
    // MARK: - Public API
    
    /// Starts automatic image capture optimized for AI analysis
    func startAutomaticCaptureForAnalysis(onImageReady: @escaping (String?) -> Void) {
        stopAutomaticCapture() // Stop any existing timer
        
        automaticCaptureTimer = Timer.scheduledTimer(withTimeInterval: configuration.captureInterval, repeats: true) { [weak self] _ in
            guard let self = self, !self.isAnalysisPending else {
                return // Skip if analysis is already pending
            }
            
            self.captureImageForAIAnalysis { encodedImage in
                onImageReady(encodedImage)
            }
        }
    }
    
    /// Stops automatic image capture
    func stopAutomaticCapture() {
        automaticCaptureTimer?.invalidate()
        automaticCaptureTimer = nil
        captureState = .idle
    }

    /// Captures a single image optimized for AI analysis
    func captureImageForAIAnalysis(completion: @escaping (String?) -> Void) {
        guard let cameraController = self.cameraController, !isAnalysisPending else {
            print("AI Analysis: Capture aborted - camera unavailable or analysis pending")
            completion(nil)
            return
        }
        
        captureState = .capturing
        
        // Capture photo using AVFoundation
        cameraController.capturePhoto { [weak self] imageData in
            guard let self = self else { return }
            
            if let data = imageData, let image = UIImage(data: data) {
                self.captureState = .captured
                
                // Process image in background thread
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let self = self else { return }
                    
                    if let encodedImage = self.prepareImageForAPIAnalysis(image: image) {
                        DispatchQueue.main.async {
                            self.processingState = .complete
                            self.captureState = .idle
                            completion(encodedImage)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.processingState = .failed(AIProcessingError.encodingFailed)
                            self.captureState = .idle
                            completion(nil)
                        }
                    }
                }
            } else {
                print("AI Analysis: Photo capture failed")
                self.captureState = .idle
                completion(nil)
            }
        }
    }
    
    // MARK: - Image Processing
    
    /// Optimizes and encodes image for AI API consumption
    func prepareImageForAPIAnalysis(image: UIImage) -> String? {
        processingState = .optimizingImage
        
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        let maxDimension = configuration.maxImageDimension
        
        // Calculate optimal scaling for AI analysis
        let widthScaleFactor = originalWidth / maxDimension
        let heightScaleFactor = originalHeight / maxDimension
        let scaleFactor = max(widthScaleFactor, heightScaleFactor)
        
        let optimizedImage: UIImage
        let finalSize: CGSize
        
        if scaleFactor > 1 {
            // Scale down for optimal AI processing
            let newWidth = originalWidth / scaleFactor
            let newHeight = originalHeight / scaleFactor
            finalSize = CGSize(width: newWidth, height: newHeight)
            
            guard let resized = resizeImageOptimally(image: image, targetSize: finalSize) else {
                processingState = .failed(AIProcessingError.resizingFailed)
                return nil
            }
            optimizedImage = resized
        } else {
            // Image already optimal size
            optimizedImage = image
            finalSize = CGSize(width: originalWidth, height: originalHeight)
        }
        
        processingState = .encodingForAPI
        
        // Compress and encode for API
        guard let imageData = optimizedImage.jpegData(compressionQuality: configuration.compressionQuality) else {
            processingState = .failed(AIProcessingError.compressionFailed)
            return nil
        }
        
        // Log metrics if enabled
        if configuration.shouldLogMetrics {
            logOptimizationMetrics(original: image, final: imageData, resolution: finalSize)
        }
        
        return "data:image/jpeg;base64," + imageData.base64EncodedString()
    }

    /// Efficiently resizes image for AI processing
    private func resizeImageOptimally(image: UIImage, targetSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    /// Logs image optimization metrics for debugging
    private func logOptimizationMetrics(original: UIImage, final: Data, resolution: CGSize) {
        let originalSize = original.jpegData(compressionQuality: 1.0)?.count ?? 0
        let optimizedSize = final.count
        let reductionPercentage = 100 - (optimizedSize * 100 / max(1, originalSize))
        
        print("AI Image Optimization:")
        print("  Original: ≈\(originalSize/1024)KB")
        print("  Optimized: ≈\(optimizedSize/1024)KB (\(reductionPercentage)% reduction)")
        print("  Resolution: \(Int(resolution.width))×\(Int(resolution.height)) px")
    }
}

// MARK: - Error Handling

enum AIProcessingError: Error, LocalizedError {
    case resizingFailed
    case compressionFailed
    case encodingFailed
    
    var errorDescription: String? {
        switch self {
        case .resizingFailed:
            return "Failed to resize image for AI analysis"
        case .compressionFailed:
            return "Failed to compress image"
        case .encodingFailed:
            return "Failed to encode image for API"
        }
    }
}
