//
//  ChessGame.swift
//  Chess
//
//  Created by exerhythm on 7/14/21.
//

import Foundation

class ChessGame {
    var board: [[ChessPiece?]] = []
    var history: [NormalMove] = []
    var logic = ChessLogic()
    
    var turnOf: ChessPieceColor {
        if let lastMove = history.last {
            let piece = piece(at: lastMove.toPos)
            return piece?.pieceColor.inverted ?? .white
        } else {
            return .white
        }
    }
    
    var delegate: ChessGameDelegate?
    
    func moves(for pos: Pos) -> [NormalMove] {
        return logic.getMoves(pos: pos, lastMove: history.last, board: board)
    }
    
    func perform(move: Move, addToHistory: Bool, uiMove: Bool, noRules: Bool) {
        if let move = move as? NormalMove, move.toPos != move.fromPos {
            let piece = piece(at: move.fromPos)
            delegate?.removePiece(self.piece(at: move.toPos))
            board[move.toPos.y][move.toPos.x] = nil
            board[move.fromPos.y][move.fromPos.x] = nil
            board[move.toPos.y][move.toPos.x] = piece
            
            if piece?.pieceType == .pawn {
                if move.toPos.y == (piece?.pieceColor == .white ? 0 : 7), uiMove, !(move.additionalMove is PawnToQueenMove) {
                    delegate?.pawnReachedEnd(color: piece!.pieceColor, completion: { [weak self] type in
                        guard let self = self else { return }
                        self.board[move.toPos.y][move.toPos.x]?.pieceType = type
                        self.checkChecks(ui: uiMove)
                        self.delegate?.changePieceType(piece: self.piece(at: move.toPos), at: move.toPos, to: type)
                        self.history.last!.additionalMove = PawnToQueenMove(pos: move.toPos, turnedTo: type)
                    })
                }
            }
            if piece?.pieceType == .king {
                if piece?.pieceColor == .white { logic.whiteCanCastle = false }
                if piece?.pieceColor == .black { logic.blackCanCastle = false }
            }
        } else if let move = move as? DestroyMove {
            delegate?.removePiece(self.piece(at: move.pos))
            board[move.pos.y][move.pos.x] = nil
        } else if let move = move as? CreateMove {
            self.piece(at: move.pos)?.removeFromParent()
            board[move.pos.y][move.pos.x] = ChessPiece(pieceColor: move.pieceColor, pieceType: move.pieceType)
            if uiMove {
                delegate?.createPiece(self.piece(at: move.pos), pos: move.pos)
            }
            
        } else if let move = move as? PawnToQueenMove {
            delegate?.changePieceType(piece: self.piece(at: move.pos), at: move.pos, to: move.turnedTo)
            board[move.pos.y][move.pos.x]?.pieceType = move.turnedTo
        }
        
        if addToHistory, let move = move as? NormalMove {
            history.append(move)
        }
        if let additionalMove = move.additionalMove {
            if additionalMove is NormalMove {
                // Castling
                let castlingMove = additionalMove as! NormalMove
                let rook = self.piece(at: castlingMove.fromPos)
                switch rook!.pieceColor {
                case .white:
                    logic.whiteCanCastle = false
                case .black:
                    logic.blackCanCastle = false
                }
            }
            perform(move: additionalMove, addToHistory: false, uiMove: uiMove, noRules: noRules)
        } else {
            logic.isWhiteInCheck = false
            logic.isBlackInCheck = false
        }
        if let move = move as? NormalMove, move.fromPos != move.toPos {
            if uiMove {
                let pieceColor = self.piece(at: move.toPos)!.pieceColor
                let check = checkCheck(forPieceColor: pieceColor.inverted, ui: uiMove)
//                if noRules { let _ = checkCheck(forPieceColor: pieceColor, ui: uiMove) } // No Rules mode
                delegate?.uiMove(piece: self.piece(at: move.toPos)!, to: move.toPos, withSound: !check)
            }
        }
    }
    
    func checkCheck(forPieceColor: ChessPieceColor, ui: Bool) -> Bool {
        logic.checkCheck(board: board)
        
        let checkmate = logic.checkCheckmate(for: forPieceColor, lastMove: history.last, board: board)
        if !checkmate {
            let check = logic.checkCheck(for: forPieceColor, board: board)
            if check {
                if ui {
                    delegate?.check(kingPos: kingPos(color: forPieceColor))
                }
                return true
            }
        } else {
            let tie = forPieceColor == .white ? !logic.isWhiteInCheck : !logic.isBlackInCheck
            if ui {
                delegate?.checkmate(kingPos: kingPos(color: forPieceColor), wins: tie ? nil : forPieceColor.inverted)
            }
            return true
        }
        return false
    }
    func checkChecks(ui: Bool) {
        let _ = self.checkCheck(forPieceColor: .white, ui: ui)
        let _ = self.checkCheck(forPieceColor: .black, ui: ui)
    }
    
    
    func undo(noRulesEnabled: Bool) {
        guard let moveToUndo = history.popLast() else { return }
        print("popped")
        delegate?.removePieces()
        resetBoard(empty: noRulesEnabled)
        for move in history {
            perform(move: move, addToHistory: false, uiMove: false, noRules: noRulesEnabled)
        }
        delegate?.createPieces()
        delegate?.uiUndoMove(fromPos: moveToUndo.toPos, toPos: moveToUndo.fromPos)
        if let rookMove = moveToUndo.additionalMove as? NormalMove {
            delegate?.uiUndoMove(fromPos: rookMove.toPos, toPos: rookMove.fromPos)
        }
        checkChecks(ui: true)
    }
    
    func kingPos(color: ChessPieceColor) -> Pos {
        for y in 0...7 {
            for x in 0...7 {
                if board[y][x]?.pieceType == .king, board[y][x]!.pieceColor == color {
                    return Pos(x: x, y: y)
                }
            }
        }
        fatalError("Unable to find the king...")
    }
    
    func resetBoard(empty: Bool, customBoard: [[ChessPiece?]]? = nil) {
        if !empty || customBoard != nil {
        board = customBoard ??
                [
//                [.init(pieceColor: .black, pieceType: .rook),.init(pieceColor: .black, pieceType: .knight),.init(pieceColor: .black, pieceType: .bishop),.init(pieceColor: .black, pieceType: .queen),.init(pieceColor: .black, pieceType: .king),.init(pieceColor: .black, pieceType: .bishop),.init(pieceColor: .black, pieceType: .knight),.init(pieceColor: .black, pieceType: .rook)],
                    [.init(pieceColor: .black, pieceType: .king),nil,nil,nil,nil,nil,nil,nil],
                [.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),],
                [nil,nil,nil,nil,nil,nil,nil,nil],
                [nil,nil,nil,nil,nil,nil,nil,nil],
                [nil,nil,nil,nil,nil,nil,nil,nil],
                [nil,nil,nil,nil,nil,nil,nil,nil],
                [.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn)],
                    [.init(pieceColor: .white, pieceType: .king),nil,nil,nil,nil,nil,nil,nil],
//                    [.init(pieceColor: .white, pieceType: .rook),.init(pieceColor: .white, pieceType: .knight),.init(pieceColor: .white, pieceType: .bishop),.init(pieceColor: .white, pieceType: .queen),.init(pieceColor: .white, pieceType: .king),.init(pieceColor: .white, pieceType: .bishop),.init(pieceColor: .white, pieceType: .knight),.init(pieceColor: .white, pieceType: .rook)]
            ]
        } else {
            board = Array(repeating:Array(repeating: nil, count: 8),count:8)
            board[0][0] = .init(pieceColor: .black, pieceType: .king)
            board[7][7] = .init(pieceColor: .white, pieceType: .king)
        }
        logic.isWhiteInCheck = false
        logic.isBlackInCheck = false
        logic.whiteCanCastle = true
        logic.blackCanCastle = true
    }
    
    func piece(at pos: Pos) -> ChessPiece? {
        return board[pos.y][pos.x]
    }
}

protocol ChessGameDelegate {
    func uiMove(piece: ChessPiece, to position: Pos, withSound: Bool)
    func pawnReachedEnd(color: ChessPieceColor,completion: @escaping (ChessPieceType) -> ())
    func check(kingPos:Pos)
    func checkmate(kingPos:Pos, wins: ChessPieceColor?)
    func createPiece(_ piece: ChessPiece?, pos: Pos)
    func removePiece(_ piece: ChessPiece?)
    func changePieceType(piece: ChessPiece?, at pos: Pos, to type: ChessPieceType)
    func createPieces()
    func removePieces()
    func uiUndoMove(fromPos: Pos, toPos: Pos)
}
