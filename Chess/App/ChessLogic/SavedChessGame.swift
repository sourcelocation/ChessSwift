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
    var finalBoard: [[Piece?]]
    var history: [NormalMove]
}
