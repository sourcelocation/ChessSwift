//
//  Models.swift
//  Chess
//
//  Created by exerhythm on 10/1/21.
//

import Foundation

extension ChessAPI {
    
    struct WaitingPlayer: Codable {
        var playerID: UUID
        var gameID: String
    }
    
    
    struct ServerGame: Codable {
        var id: String
        var players: [Player]
        var whiteID: String?
        var chessGame: Game?
        var difficulty: Difficulty
        
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
        struct Player: Codable {
            var id: UUID
            var username: String
        }
        
        class Game: Codable {
            var board: [[ChessPiece?]]
            var history: [NormalMove]
            
            class ChessPiece: Codable {
                var pieceColor: ChessPieceColor = .white
                var pieceType: ChessPieceType = .pawn
                
                init(pieceColor: ChessPieceColor, pieceType: ChessPieceType) {
                    self.pieceColor = pieceColor
                    self.pieceType = pieceType
                }
            }

        }

    }
    
    struct Login: Codable {
        var id: UUID
        var username: String
        var passwordHash: String
    }
}
