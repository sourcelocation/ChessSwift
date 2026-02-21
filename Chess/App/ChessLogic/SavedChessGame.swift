//
//  SavedChessGame.swift
//  Chess
//
//  Created by exerhythm on 05.07.2022.
//

import Foundation

struct SavedChessGame: Codable {
    struct Piece: Codable {
        var type: ChessPieceType
        var color: ChessPieceColor
    }

    var id: UUID
    var createdAt: Date?
    var finalBoard: [[Piece?]]
    var history: StoredGameHistory

    init(id: UUID, createdAt: Date?, finalBoard: [[Piece?]], history: StoredGameHistory) {
        self.id = id
        self.createdAt = createdAt
        self.finalBoard = finalBoard
        self.history = history
    }
}
