//
//  CameraCaptureView.swift
//  context-camera
//
//  Camera view using AVFoundation for optimized capture
//  Designed for AI image analysis with Moondream API
//

import SwiftUI
import AVFoundation
import UIKit

/// States that the camera can be in during capture process
enum CaptureState {
    case ready          // Ready to capture
    case capturing      // Currently taking snapshot
    case processing     // Processing image for API
    case idle           // Not actively being used
}

/// A specialized camera view for capturing images to send to AI captioning services
struct CameraCaptureView: UIViewRepresentable {
    @Binding var cameraView: CameraController?
    @Binding var captureState: CaptureState
    
    func makeUIView(context: Context) -> UIView {
        let controller = CameraController()
        
        // Update the binding
        DispatchQueue.main.async {
            self.cameraView = controller
        }
        
        return controller.previewView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Updates handled by CameraController
    }
}

/// Camera controller optimized for AI image analysis
class CameraController: NSObject, ObservableObject {
    let previewView = UIView()
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoCaptureDevice: AVCaptureDevice?
    
    // Capture completion callback
    private var captureCompletion: ((Data?) -> Void)?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let session = AVCaptureSession()
            
            // Use .medium preset for faster capture (optimized for AI)
            session.sessionPreset = .medium
            
            guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
                print("Failed to create camera input")
                return
            }
            
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
                self.videoCaptureDevice = videoCaptureDevice
            }
            
            let photoOutput = AVCapturePhotoOutput()
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                
                // Optimize for speed over quality for AI analysis
                photoOutput.isHighResolutionCaptureEnabled = false
                
                self.photoOutput = photoOutput
            }
            
            self.captureSession = session
            
            DispatchQueue.main.async {
                self.setupPreviewLayer()
                session.startRunning()
            }
        }
    }
    
    private func setupPreviewLayer() {
        guard let captureSession = captureSession else { return }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = previewView.bounds
        
        previewView.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
        
        // Update layer frame when view bounds change
        previewView.layoutIfNeeded()
    }
    
    /// Capture photo optimized for AI analysis
    func capturePhoto(completion: @escaping (Data?) -> Void) {
        guard let photoOutput = photoOutput else {
            completion(nil)
            return
        }
        
        self.captureCompletion = completion
        
        // Create photo settings optimized for AI processing
        let photoSettings = AVCapturePhotoSettings()
        
        // Disable flash for consistent AI analysis
        photoSettings.flashMode = .off
        
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    deinit {
        captureSession?.stopRunning()
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print("Photo capture error: \(error!.localizedDescription)")
            captureCompletion?(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("Failed to get photo data")
            captureCompletion?(nil)
            return
        }
        
        // Process image for AI analysis on background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let optimizedData = self?.optimizeImageForAI(imageData)
            
            DispatchQueue.main.async {
                self?.captureCompletion?(optimizedData)
                self?.captureCompletion = nil
            }
        }
    }
    
    /// Optimize image for AI analysis (resize and compress)
    private func optimizeImageForAI(_ imageData: Data) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }
        
        // Resize to 192x192 for optimal AI processing speed
        let targetSize = CGSize(width: 192, height: 192)
        let resizedImage = resizeImage(image, to: targetSize)
        
        // Compress with 0.1 quality for fast upload
        return resizedImage.jpegData(compressionQuality: 0.1)
    }
    
    /// Fast image resizing optimized for speed
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Backward Compatibility
typealias ARViewContainer = CameraCaptureView
