//
//  ChessGame.swift
//  Chess
//
//  Created by exerhythm on 7/14/21.
//

import Foundation

enum GameType {
    case overTheBoard, online, puzzle, engine
}

class ChessGame {
    private struct FenPiece {
        var color: ChessPieceColor
        var type: ChessPieceType
    }

    var board: [[ChessPiece?]] = []
    var history: [NormalMove] = []
    var slicedHistory: [NormalMove] {
        currentMoveIHistory != nil ? Array(history.prefix(upTo: currentMoveIHistory! + 1)) : []
    }
    var onlineTurnOf: ChessPieceColor? // todo
    var turnOf: ChessPieceColor {
        if onlineTurnOf == nil {
            if let lastMove = slicedHistory.last {
                let piece = piece(at: lastMove.toPos)
                return piece?.pieceColor.inverted ?? .white
            } else {
                return .white
            }
        } else {
            return onlineTurnOf!
        }
    }
    var currentMoveIHistory: Int?
    var logic = ChessLogic()
    
    static let initialBoard: [[ChessPiece?]] = [
        [.init(pieceColor: .black, pieceType: .rook),.init(pieceColor: .black, pieceType: .knight),.init(pieceColor: .black, pieceType: .bishop),.init(pieceColor: .black, pieceType: .queen),.init(pieceColor: .black, pieceType: .king),.init(pieceColor: .black, pieceType: .bishop),.init(pieceColor: .black, pieceType: .knight),.init(pieceColor: .black, pieceType: .rook)],
        [.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),],
        [nil,nil,nil,nil,nil,nil,nil,nil],
        [nil,nil,nil,nil,nil,nil,nil,nil],
        [nil,nil,nil,nil,nil,nil,nil,nil],
        [nil,nil,nil,nil,nil,nil,nil,nil],
        [.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn)],
        [.init(pieceColor: .white, pieceType: .rook),.init(pieceColor: .white, pieceType: .knight),.init(pieceColor: .white, pieceType: .bishop),.init(pieceColor: .white, pieceType: .queen),.init(pieceColor: .white, pieceType: .king),.init(pieceColor: .white, pieceType: .bishop),.init(pieceColor: .white, pieceType: .knight),.init(pieceColor: .white, pieceType: .rook)]
    ]
    
    var delegate: ChessGameDelegate?
    
    
    func piece(at pos: Pos) -> ChessPiece? {
        return board[pos.y][pos.x]
    }
    func moves(for pos: Pos) -> [NormalMove] {
        return logic.getMoves(pos: pos, lastMove: history.last, board: board)
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
            if currentMoveIHistory != nil, history.count != 0, currentMoveIHistory != history.count - 1 {
                // make redo no longer available
                history.removeSubrange(currentMoveIHistory! + 1...history.count - 1)
            } else if currentMoveIHistory == nil, history.count != 0 {
                history = []
            }
            history.append(move)
            currentMoveIHistory = history.count - 1
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
                if noRules { let _ = checkCheck(forPieceColor: pieceColor, ui: uiMove) } // No Rules mode
                delegate?.uiMove(piece: self.piece(at: move.toPos)!, to: move.toPos, withSound: !check)
            }
        }
    }
    
    func checkCheck(forPieceColor: ChessPieceColor, ui: Bool) -> Bool {
        logic.checkCheck(board: board)
        
        let checkmate = logic.checkCheckmate(for: forPieceColor, lastMove: slicedHistory.last, board: board)
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
    
    func moveHistoryToBeginning() {
        guard history.count > 0 else { return }
        currentMoveIHistory = 0
        delegate?.removePieces()
        resetBoard()
        delegate?.createPieces()
    }
    func undo(noRulesEnabled: Bool) {
        guard currentMoveIHistory != nil else { return }
        let moveToUndo = history[currentMoveIHistory!]
        
        currentMoveIHistory! -= 1
        if currentMoveIHistory! < 0 {
            currentMoveIHistory = nil
        }
        
        delegate?.removePieces()
        if noRulesEnabled {
            var emptyBoardPieces: [[ChessPiece?]] = Array(repeating:Array(repeating: nil, count: 8),count:8)
            emptyBoardPieces[0][0] = .init(pieceColor: .black, pieceType: .king)
            emptyBoardPieces[7][7] = .init(pieceColor: .white, pieceType: .king)
            
            resetBoard(customBoard: emptyBoardPieces)
        } else {
            resetBoard()
        }
        for move in slicedHistory {
            perform(move: move, addToHistory: false, uiMove: false, noRules: noRulesEnabled)
        }
        delegate?.createPieces()
        delegate?.uiUndoMove(fromPos: moveToUndo.toPos, toPos: moveToUndo.fromPos)
        if let rookMove = moveToUndo.additionalMove as? NormalMove {
            delegate?.uiUndoMove(fromPos: rookMove.toPos, toPos: rookMove.fromPos)
        }
        checkChecks(ui: true)
    }
    
    func redo(noRulesEnabled: Bool) {
        guard currentMoveIHistory == nil || currentMoveIHistory! < history.count - 1 else { return }
        if currentMoveIHistory != nil {
            currentMoveIHistory! += 1
        } else if history.count > 0 {
            currentMoveIHistory = 0
        }
        let moveToRedo = history[currentMoveIHistory!]
        
        perform(move: moveToRedo, addToHistory: false, uiMove: true, noRules: noRulesEnabled)
        
//        delegate?.uiMove(piece: piece(at: moveToRedo.fromPos)!, to: moveToRedo.toPos, withSound: true)
//        if let rookMove = moveToRedo.additionalMove as? NormalMove {
//            delegate?.uiMove(piece: piece(at: rookMove.fromPos)!, to: rookMove.toPos, withSound: false)
//        }
//        checkChecks(ui: true)
    }
    
    func resetBoard(customBoard: [[ChessPiece?]]? = nil) {
        board = customBoard ?? [
            [.init(pieceColor: .black, pieceType: .rook),.init(pieceColor: .black, pieceType: .knight),.init(pieceColor: .black, pieceType: .bishop),.init(pieceColor: .black, pieceType: .queen),.init(pieceColor: .black, pieceType: .king),.init(pieceColor: .black, pieceType: .bishop),.init(pieceColor: .black, pieceType: .knight),.init(pieceColor: .black, pieceType: .rook)],
            [.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),],
            [nil,nil,nil,nil,nil,nil,nil,nil],
            [nil,nil,nil,nil,nil,nil,nil,nil],
            [nil,nil,nil,nil,nil,nil,nil,nil],
            [nil,nil,nil,nil,nil,nil,nil,nil],
            [.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn)],
            [.init(pieceColor: .white, pieceType: .rook),.init(pieceColor: .white, pieceType: .knight),.init(pieceColor: .white, pieceType: .bishop),.init(pieceColor: .white, pieceType: .queen),.init(pieceColor: .white, pieceType: .king),.init(pieceColor: .white, pieceType: .bishop),.init(pieceColor: .white, pieceType: .knight),.init(pieceColor: .white, pieceType: .rook)]
        ]
        logic.isWhiteInCheck = false
        logic.isBlackInCheck = false
        logic.whiteCanCastle = true
        logic.blackCanCastle = true
    }
    func getFen() -> String {
        var s = ""
        var e = 0

        for i in (0 ..< 64) {
            let pos = Pos(x: i % 8, y: i / 8)
            let piece = piece(at: pos)
            if piece == nil {
                e += 1
            } else {
                if e != 0 {
                    s += String(e)
                    e = 0
                }
                s += piece!.letterFenRepresentation()
            }
            
            if i % 8 == 7 {
                if e != 0 {
                    s += String(e)
                }
                if i < 63 {
                    s += "/"
                }
                e = 0
            }
        }
        
        s += (turnOf == .white ? " w " : " b ") + getFenCastleRights() + " "
        
        if let lastMove = slicedHistory.last, lastMove.doublePawnMove {
            s += posToCoordinateString(.init(x: lastMove.toPos.x, y: lastMove.toPos.y - (turnOf == .white ? 1 : -1)))
        } else {
            s +=  "-"
        }
        
        let (halfmoveClock, fullmoveNumber) = fenCounters()
        s +=  " \(halfmoveClock) \(fullmoveNumber)"
        
        return s
    }
    
    func getFenCastleRights() -> String {
        var s = ""
        if canCastleKingSide(.white) {
            s += "K"
        }
        if canCastleQueenSide(.white) {
            s += "Q"
        }
        if canCastleKingSide(.black) {
            s += "k"
        }
        if canCastleQueenSide(.black) {
            s += "q"
        }
        if s.isEmpty { s = "-" }
        
        return s
    }
    
    private func canCastleKingSide(_ color: ChessPieceColor) -> Bool {
        let kingPos = Pos(x: 4, y: color == .white ? 7 : 0)
        let rookPos = Pos(x: 7, y: color == .white ? 7 : 0)
        
        guard let king = piece(at: kingPos),
              let rook = piece(at: rookPos),
              king.pieceType == .king,
              rook.pieceType == .rook,
              king.pieceColor == color,
              rook.pieceColor == color
        else {
            return false
        }
        
        return !hasHistoryTouching(square: kingPos) && !hasHistoryTouching(square: rookPos)
    }
    
    private func canCastleQueenSide(_ color: ChessPieceColor) -> Bool {
        let kingPos = Pos(x: 4, y: color == .white ? 7 : 0)
        let rookPos = Pos(x: 0, y: color == .white ? 7 : 0)
        
        guard let king = piece(at: kingPos),
              let rook = piece(at: rookPos),
              king.pieceType == .king,
              rook.pieceType == .rook,
              king.pieceColor == color,
              rook.pieceColor == color
        else {
            return false
        }
        
        return !hasHistoryTouching(square: kingPos) && !hasHistoryTouching(square: rookPos)
    }
    
    private func hasHistoryTouching(square: Pos) -> Bool {
        slicedHistory.contains(where: { moveTouchesSquare($0, square: square) })
    }
    
    private func moveTouchesSquare(_ move: Move, square: Pos) -> Bool {
        if let normalMove = move as? NormalMove {
            if normalMove.fromPos == square || normalMove.toPos == square {
                return true
            }
        } else if let destroyMove = move as? DestroyMove {
            if destroyMove.pos == square {
                return true
            }
        } else if let createMove = move as? CreateMove {
            if createMove.pos == square {
                return true
            }
        } else if let promotion = move as? PawnToQueenMove {
            if promotion.pos == square {
                return true
            }
        }
        
        if let additionalMove = move.additionalMove {
            return moveTouchesSquare(additionalMove, square: square)
        }
        return false
    }
    
    private func fenCounters() -> (halfmove: Int, fullmove: Int) {
        var tempBoard = ChessGame.initialBoard.map { row in
            row.map { piece -> FenPiece? in
                guard let piece else { return nil }
                return FenPiece(color: piece.pieceColor, type: piece.pieceType)
            }
        }
        
        var halfmoveClock = 0
        var fullmoveNumber = 1
        var sideToMove: ChessPieceColor = .white
        
        for move in slicedHistory {
            guard let fromPos = move.fromPos, let toPos = move.toPos else { continue }
            let movingPiece = tempBoard[fromPos.y][fromPos.x]
            let isPawnMove = movingPiece?.type == .pawn
            let isCapture = (fromPos != toPos && tempBoard[toPos.y][toPos.x] != nil) || move.additionalMove is DestroyMove
            
            if isPawnMove || isCapture {
                halfmoveClock = 0
            } else {
                halfmoveClock += 1
            }
            
            applyMoveToFenBoard(move, board: &tempBoard)
            
            if sideToMove == .black {
                fullmoveNumber += 1
            }
            sideToMove = sideToMove.inverted
        }
        
        return (halfmoveClock, fullmoveNumber)
    }
    
    private func applyMoveToFenBoard(_ move: Move, board: inout [[FenPiece?]]) {
        if let normalMove = move as? NormalMove {
            if normalMove.fromPos != normalMove.toPos {
                let piece = board[normalMove.fromPos.y][normalMove.fromPos.x]
                board[normalMove.fromPos.y][normalMove.fromPos.x] = nil
                board[normalMove.toPos.y][normalMove.toPos.x] = piece
            }
        } else if let destroyMove = move as? DestroyMove {
            board[destroyMove.pos.y][destroyMove.pos.x] = nil
        } else if let createMove = move as? CreateMove {
            board[createMove.pos.y][createMove.pos.x] = FenPiece(color: createMove.pieceColor, type: createMove.pieceType)
        } else if let promotion = move as? PawnToQueenMove {
            if var piece = board[promotion.pos.y][promotion.pos.x] {
                piece.type = promotion.turnedTo
                board[promotion.pos.y][promotion.pos.x] = piece
            }
        }
        
        if let additional = move.additionalMove {
            applyMoveToFenBoard(additional, board: &board)
        }
    }
    
    func posToCoordinateString(_ pos: Pos) -> String {
        return ["a","b","c","d","e","f","g","h"][pos.x] + String(8 - pos.y)
    }
    func printBoard() {
        for row in board {
            print(row.map({
                if $0 != nil {
                    var res = ""
                    switch $0!.pieceType {
                    case .bishop:
                        res = "b"
                    case .king:
                        res = "K"
                    case .knight:
                        res = "k"
                    case .pawn:
                        res = "p"
                    case .queen:
                        res = "Q"
                    case .rook:
                        res = "r"
                    }
                    return res
                } else {
                    return "."
                }
            } as (ChessPiece?) -> String).joined(separator: " "))
        }
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
