//
//  ChessPiece.swift
//  Chess
//
//  Created by sourcelocation on 07/11/2023.
//

import SpriteKit

class ChessPiece: SKSpriteNode {
    var pieceColor: ChessPieceColor = .white
    var pieceType: ChessPieceType = .pawn
    var id = UUID()
    init(pieceColor: ChessPieceColor, pieceType: ChessPieceType) {
        self.pieceColor = pieceColor
        self.pieceType = pieceType
        let imageName = pieceType.rawValue + "-" + pieceColor.rawValue
        let texture = SKTexture(imageNamed: imageName)
        
        super.init(texture: texture, color: .clear, size: texture.size())
    }
    convenience init(_ pieceColor: ChessPieceColor, _ pieceType: ChessPieceType) {
        self.init(pieceColor: pieceColor, pieceType: pieceType)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    func letterFenRepresentation() -> String {
        var l = ""
        switch pieceType {
        case .pawn:
            l = "p"
        case .knight:
            l = "n"
        case .bishop:
            l = "b"
        case .rook:
            l = "r"
        case .queen:
            l = "q"
        case .king:
            l = "k"
        }
        return pieceColor == .black ? l : l.uppercased()
    }
}
