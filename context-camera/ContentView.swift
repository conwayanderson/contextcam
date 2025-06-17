//
//  ContentView.swift
//  context-camera
//
//  Updated to use AVFoundation camera with sequential AI capture
//

import SwiftUI
import UIKit
import Foundation

struct ContentView: View {
    @StateObject private var contextManager = ContextManager.shared
    @State private var cameraController: CameraController?
    @State private var apiResponse = ""
    @State private var isAnalysisPending = false
    
    // UI state management
    @State private var showGreenFlash = false
    @State private var showMessage = false
    @State private var displayText = ""
    @State private var captureState: CaptureState = .ready
    
    // Sequential capture state
    @State private var isContinuousCapture = false
    
    func calculateBase64SizeInBytes(base64String: String) {
        let base64Length = base64String.count
        let sizeInBytes = (base64Length * 3) / 4
        let sizeInKiloBytes = sizeInBytes / 1024
        print("AI Analysis: Image size ≈\(sizeInKiloBytes)KB")
    }
    
    func sendImageForCaption(imageData: Data) {
        isAnalysisPending = true
        
        // Convert image data to base64
        let base64String = imageData.base64EncodedString()
        calculateBase64SizeInBytes(base64String: base64String)
        
        // Create data URL for Moondream
        let dataURL = "data:image/jpeg;base64,\(base64String)"
        
        MoondreamService.shared.generateCaption(for: dataURL) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let caption):
                    self.apiResponse = caption
                    self.isAnalysisPending = false
                    
                    // Check for contexts using direct queries to Moondream
                    ContextManager.shared.checkForContexts(imageBase64: dataURL) { action in
                        DispatchQueue.main.async {
                            if let action = action {
                                self.triggerActionUI(actionText: action.actionText)
                            }
                        }
                    }
                    
                    // Continue capturing if continuous mode is enabled
                    if self.isContinuousCapture {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.captureImageForAnalysis()
                        }
                    }
                    
                case .failure(let error):
                    self.apiResponse = error.localizedDescription
                    self.isAnalysisPending = false
                    
                    // Continue capturing even on error if continuous mode is enabled
                    if self.isContinuousCapture {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.captureImageForAnalysis()
                        }
                    }
                }
            }
        }
    }
    
    /// Trigger the visual feedback for detected actions
    private func triggerActionUI(actionText: String) {
        displayText = actionText
        
        withAnimation(.easeInOut(duration: 0.5)) {
            showGreenFlash = true
            showMessage = true
        }
        
        // Auto-hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                showGreenFlash = false
                showMessage = false
            }
        }
    }
    
    /// Start continuous sequential capture
    private func startContinuousCapture() {
        guard !isContinuousCapture else { return }
        
        isContinuousCapture = true
        captureState = .capturing
        
        // Start the first capture
        captureImageForAnalysis()
        
        print("Started continuous sequential capture")
    }
    
    /// Stop continuous capture
    private func stopContinuousCapture() {
        isContinuousCapture = false
        captureState = .ready
        
        print("Stopped continuous capture")
    }
    
    /// Capture a single image for AI analysis
    private func captureImageForAnalysis() {
        // Don't capture if already processing
        guard !isAnalysisPending else {
            print("Skipping capture - analysis still pending")
            return
        }
        
        cameraController?.capturePhoto { imageData in
            DispatchQueue.main.async {
                if let imageData = imageData {
                    self.sendImageForCaption(imageData: imageData)
                } else {
                    print("Failed to capture image")
                    // Retry after a delay if in continuous mode
                    if self.isContinuousCapture {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.captureImageForAnalysis()
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            CameraCaptureView(cameraView: $cameraController, captureState: $captureState)
                .edgesIgnoringSafeArea(.all)
            
            // Success flashing UI
            if showGreenFlash {
                Color.green.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .zIndex(1)
            }
            
            // Message display
            if showMessage {
                VStack {
                    Text(displayText)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(15)
                }
                .zIndex(2)
                .transition(.scale.combined(with: .opacity))
            }

            VStack {
                Spacer()

                // AI Analysis Status
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(isAnalysisPending ? Color.orange : (isContinuousCapture ? Color.green : Color.gray))
                                .frame(width: 12, height: 12)
                            
                            Text(isAnalysisPending ? "Analyzing..." : (isContinuousCapture ? "Live Capture" : "Stopped"))
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        // Current AI Response
                        if !apiResponse.isEmpty {
                            Text(apiResponse)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                                .lineLimit(3)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                                
                Button(action: {
                    // Toggle continuous capture
                    if isContinuousCapture {
                        stopContinuousCapture()
                    } else {
                        startContinuousCapture()
                    }
                }) {
                    Image(systemName: isContinuousCapture ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title)
                        .padding()
                        .foregroundColor(Color.white)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding(.bottom, 40)
            }
        }
        .onDisappear {
            // Stop capture when view disappears
            stopContinuousCapture()
        }
    }
}

// Custom modifier to always show scroll indicators
struct AlwaysShowScrollIndicators: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                UIScrollView.appearance().showsVerticalScrollIndicator = true
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
