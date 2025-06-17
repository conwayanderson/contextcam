import Foundation
import SwiftUI

struct KeywordPair {
    let keywords: [String]
    let actionText: String
}

class KeywordActionManager: ObservableObject {
    static let shared = KeywordActionManager()
    
    // Hand gesture detection keyword pairs
    let keywordPairs: [KeywordPair] = [
        KeywordPair(keywords: ["thumbs", "up"], actionText: "👍 Thumbs Up!"),
        KeywordPair(keywords: ["peace", "sign"], actionText: "✌️ Peace Sign!"),
    ]
    
    func processKeywords(in outputString: String) -> KeywordPair? {
        print("Checking output for keywords: \(outputString)")
        for keywordPair in keywordPairs {
            print("Checking against keywords: \(keywordPair.keywords)")
            if keywordPair.keywords.allSatisfy(outputString.localizedCaseInsensitiveContains) {
                print("Match found: \(keywordPair.actionText)")
                return keywordPair
            }
        }
        print("No gesture match found.")
        return nil
    }
}
