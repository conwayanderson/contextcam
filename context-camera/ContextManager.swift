import Foundation
import SwiftUI

struct ContextQuery {
    let question: String
    let actionText: String
}

class ContextManager: ObservableObject {
    static let shared = ContextManager()
    
    // Context queries for context detection
    let contextQueries: [ContextQuery] = [
        ContextQuery(question: "Is the person petting a dog? Answer yes or no.", actionText: "good pup!")
    ]
    
    func checkForContexts(imageBase64: String, completion: @escaping (ContextQuery?) -> Void) {
        print("Checking for contexts using direct Moondream queries...")
        
        // Check each query sequentially
        checkNextQuery(imageBase64: imageBase64, queryIndex: 0, completion: completion)
    }
    
    private func checkNextQuery(imageBase64: String, queryIndex: Int, completion: @escaping (ContextQuery?) -> Void) {
        // If we've checked all queries, return nil
        guard queryIndex < contextQueries.count else {
            print("No context matches found.")
            completion(nil)
            return
        }
        
        let query = contextQueries[queryIndex]
        print("Asking: \(query.question)")
        
        MoondreamService.shared.queryImage(imageBase64, question: query.question) { [weak self] result in
            switch result {
            case .success(let answer):
                print("Response: \(answer)")
                
                // Check if response contains "yes" (case insensitive)
                if answer.lowercased().contains("yes") {
                    print("Match found: \(query.actionText)")
                    completion(query)
                    return
                } else {
                    // Check next query
                    self?.checkNextQuery(imageBase64: imageBase64, queryIndex: queryIndex + 1, completion: completion)
                }
                
            case .failure(let error):
                print("Query failed: \(error.localizedDescription)")
                // Continue to next query even if this one failed
                self?.checkNextQuery(imageBase64: imageBase64, queryIndex: queryIndex + 1, completion: completion)
            }
        }
    }
}
