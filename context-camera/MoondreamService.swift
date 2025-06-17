//
//  MoondreamService.swift
//  context-camera
//
//  Service for handling Moondream AI API interactions
//

import Foundation

/// Service for interacting with the Moondream AI API
class MoondreamService {
    static let shared = MoondreamService()
    
    private init() {}
    
    /// Send an image to Moondream for caption generation
    /// - Parameters:
    ///   - imageBase64: Base64 encoded image with data URL prefix
    ///   - completion: Completion handler with result
    func generateCaption(for imageBase64: String, completion: @escaping (Result<String, MoondreamError>) -> Void) {
        guard Config.Moondream.isConfigured else {
            completion(.failure(.missingAPIKey))
            return
        }
        
        let startTime = Date()
        
        // Prepare the request
        guard let url = URL(string: "\(Config.Moondream.baseURL)/caption") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.Moondream.apiKey, forHTTPHeaderField: "X-Moondream-Auth")
        
        // Prepare the request body
        let requestBody: [String: Any] = [
            "image_url": imageBase64,
            "length": "short"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(.encodingError(error)))
            return
        }
        
        // Make the API call
        URLSession.shared.dataTask(with: request) { data, response, error in
            let responseTime = Date().timeIntervalSince(startTime)
            print("⏱️ API Response Time: \(String(format: "%.2f", responseTime))s")
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(httpResponse.statusCode)")
            }
            
            if let error = error {
                print("❌ Network Error: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                print("❌ No data received")
                completion(.failure(.noData))
                return
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("📋 Raw API Response: \(responseString)")
            }
            
            // Parse the response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("📋 Parsed JSON: \(json)")
                    if let caption = json["caption"] as? String {
                        completion(.success(caption))
                    } else {
                        print("❌ No 'caption' field in response")
                        let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                        completion(.failure(.invalidResponseFormat(responseString)))
                    }
                } else {
                    print("❌ Failed to parse JSON")
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                    completion(.failure(.invalidResponseFormat(responseString)))
                }
            } catch {
                print("❌ JSON Parsing Error: \(error)")
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
    
    /// Send an image to Moondream with a custom question
    /// - Parameters:
    ///   - imageBase64: Base64 encoded image with data URL prefix
    ///   - question: Question to ask about the image
    ///   - completion: Completion handler with result
    func queryImage(_ imageBase64: String, question: String, completion: @escaping (Result<String, MoondreamError>) -> Void) {
        guard Config.Moondream.isConfigured else {
            completion(.failure(.missingAPIKey))
            return
        }
        
        guard let url = URL(string: "\(Config.Moondream.baseURL)/query") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.Moondream.apiKey, forHTTPHeaderField: "X-Moondream-Auth")
        
        let requestBody: [String: Any] = [
            "image_url": imageBase64,
            "question": question + " respond with one sentence"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(.encodingError(error)))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let answer = json["answer"] as? String {
                    completion(.success(answer))
                } else {
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                    completion(.failure(.invalidResponseFormat(responseString)))
                }
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
}

/// Errors that can occur when using the Moondream service
enum MoondreamError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case encodingError(Error)
    case networkError(Error)
    case invalidResponse
    case noData
    case decodingError(Error)
    case invalidResponseFormat(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Moondream API key is not configured. Please set MOONDREAM_API_KEY in your environment or Info.plist."
        case .invalidURL:
            return "Invalid Moondream API URL"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .invalidResponseFormat(let response):
            return "Invalid response format: \(response)"
        }
    }
}
