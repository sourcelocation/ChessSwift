//
//  Models.swift
//  Chess
//
//  Created by exerhythm on 10/1/21.
//

import Foundation

extension ChessAPI {
    
    enum Difficulty: String, Codable {
        case beginner, intermediate, advanced
        
        func localized() -> String {
            switch self {
            case .beginner:
                return "Beginner"
            case .intermediate:
                return "Intermediate"
            case .advanced:
                return "Advanced"
            }
        }
    }
    
    enum State: String, Codable {
        case waiting = "waiting"
        case running = "running"
    }
    
    struct PublicGame: Codable {
        var id: UUID?
        var state: State
        var difficulty: Difficulty
        var time: Int
    }
    
    struct Game: Codable {
        var id: UUID?
        var state: State
        var difficulty: Difficulty
        var time: Int
        var whitePlayeriD: UUID?
        
        var lastMove: NormalMove?
    }
    
    struct Login: Codable {
        var id: UUID
        var username: String
        var key: String
    }
}
