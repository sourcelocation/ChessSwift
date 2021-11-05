//
//  Models.swift
//  Chess
//
//  Created by exerhythm on 7/23/21.
//

import Foundation


enum ChessPieceType: String, Codable {
    case king,queen,rook,bishop,knight,pawn
}

enum ChessPieceColor: String, Codable {
    case white,black
}
extension ChessPieceColor {
    var inverted: ChessPieceColor {
        return self == .white ? .black : .white
    }
}


class Move: Codable {
    var additionalMove: Move?
    
    enum CodingKeys : String, CodingKey {
        case additionalMove
        case type
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(additionalMove, forKey: .additionalMove)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.additionalMove = try container.decodeIfPresent(Move.self, forKey: .additionalMove)
    }
    
    init(additionalMove: Move? = nil) {
        self.additionalMove = additionalMove
    }
}
class Pos: Codable, Equatable {
    static func == (lhs: Pos, rhs: Pos) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    var x: Int
    var y: Int
    
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}
class NormalMove: Move {
    var fromPos: Pos!
    var toPos: Pos!
    
    var doublePawnMove = false
    
    private enum CodingKeys : String, CodingKey {
        case fromPos, toPos, type, doublePawnMove, additionalMove
    }
    enum MoveTypeKey: CodingKey {
        case type
    }
    enum MoveTypes: String, Decodable {
        case normalMove = "normal"
        case destroyMove = "destroy"
        case createMove = "create"
        case pawnToQueenMove = "pawnToQueen"
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fromPos, forKey: .fromPos)
        try container.encode(toPos, forKey: .toPos)
        try container.encode(doublePawnMove, forKey: .doublePawnMove)
    }
    
    init(from fromPos: Pos, to toPos: Pos, additionalMove: Move? = nil, doublePawnMove: Bool = false) {
        super.init(additionalMove: additionalMove)
        self.additionalMove = additionalMove
        self.fromPos = fromPos
        self.toPos = toPos
        self.doublePawnMove = doublePawnMove
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fromPos = try container.decode(Pos.self, forKey: .fromPos)
        toPos = try container.decode(Pos.self, forKey: .toPos)
        doublePawnMove = try container.decode(Bool.self, forKey: .doublePawnMove)
        
        if container.contains(.additionalMove) {
            let additionalMoveContainer = try container.nestedContainer(keyedBy: MoveTypeKey.self, forKey: .additionalMove)
            let type = try additionalMoveContainer.decodeIfPresent(MoveTypes.self, forKey: .type) ?? .normalMove
            
            switch type {
            case .normalMove:
                additionalMove = try container.decode(NormalMove.self, forKey: .additionalMove)
            case .pawnToQueenMove:
                additionalMove = try container.decode(PawnToQueenMove.self, forKey: .additionalMove)
            case .destroyMove:
                additionalMove = try container.decode(DestroyMove.self, forKey: .additionalMove)
            case .createMove:
                additionalMove = try container.decode(CreateMove.self, forKey: .additionalMove)
            }
        }
    }
}

class PawnToQueenMove: Move {
    var pos: Pos!
    var turnedTo: ChessPieceType!
    
    private enum CodingKeys : String, CodingKey {
        case pos, turnedTo, type
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pos, forKey: .pos)
        try container.encode(turnedTo, forKey: .turnedTo)
        try container.encode("pawnToQueen", forKey: .type)
    }
    
    init(pos: Pos, turnedTo: ChessPieceType) {
        super.init(additionalMove: nil)
        self.pos = pos
        self.turnedTo = turnedTo
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pos = try container.decode(Pos.self, forKey: .pos)
        turnedTo = try container.decode(ChessPieceType.self, forKey: .turnedTo)
        try super.init(from: decoder)
    }
}

// For "No rules" mode
class CreateMove: Move {
    var pos: Pos!
    var pieceType: ChessPieceType!
    var pieceColor: ChessPieceColor!
    
    private enum CodingKeys : String, CodingKey {
        case pos, pieceType, pieceColor, type
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pos, forKey: .pos)
        try container.encode(pieceType, forKey: .pieceType)
        try container.encode(pieceColor, forKey: .pieceColor)
        try container.encode("create", forKey: .type)
    }
    
    init(pos: Pos,pieceType: ChessPieceType, pieceColor: ChessPieceColor) {
        super.init(additionalMove: nil)
        self.pos = pos
        self.pieceType = pieceType
        self.pieceColor = pieceColor
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pos = try container.decode(Pos.self, forKey: .pos)
        pieceType = try container.decode(ChessPieceType.self, forKey: .pieceType)
        pieceColor = try container.decode(ChessPieceColor.self, forKey: .pieceColor)
        try super.init(from: decoder)
    }
}

class DestroyMove: Move {
    var pos: Pos!
    
    private enum CodingKeys : String, CodingKey {
        case pos, type
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pos, forKey: .pos)
        try container.encode("destroy", forKey: .type)
    }
    
    init(pos: Pos) {
        super.init(additionalMove: nil)
        self.pos = pos
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pos = try container.decode(Pos.self, forKey: .pos)
        try super.init(from: decoder)
    }
}



class History: Decodable {
    var moves: [NormalMove]
    
    enum MoveTypeKey: CodingKey {
        case type
    }
    enum MoveTypes: String, Decodable {
        case normalMove = "normal"
        case enPassantMove = "enPassant"
        case destroy = "destroy"
        case create = "create"
    }
    
    required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var moves: [NormalMove] = []
        
        while (!container.isAtEnd) {
            moves.append(try container.decode(NormalMove.self))
        }
        self.moves = moves
    }
}




