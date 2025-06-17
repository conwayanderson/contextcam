//
//  Config.swift
//  context-camera
//
//  Configuration management for the Context Camera app
//

import Foundation

struct Config {
    /// Moondream API configuration
    struct Moondream {
        /// API base URL for Moondream service
        static let baseURL = "https://api.moondream.ai/v1"
        
        /// API key for Moondream service
        /// Set this in your environment or Info.plist
        static var apiKey: String {
            // First try to get from environment variable
            if let envKey = ProcessInfo.processInfo.environment["MOONDREAM_API_KEY"] {
                return envKey
            }
            
            // Fallback to Info.plist
            if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
               let plist = NSDictionary(contentsOfFile: path),
               let key = plist["MOONDREAM_API_KEY"] as? String {
                return key
            }
            
            // Return empty string if not found - app should handle this gracefully
            return ""
        }
        
        /// Check if API key is configured
        static var isConfigured: Bool {
            return !apiKey.isEmpty
        }
    }
    
    /// Image processing configuration
    struct ImageProcessing {
        /// Maximum dimension for images sent to Moondream API
        static let maxDimension: CGFloat = 320
        
        /// JPEG compression quality for API calls
        static let compressionQuality: CGFloat = 0.5
        
        /// Snapshot capture interval in seconds
        static let captureInterval: TimeInterval = 1.5
    }
}
