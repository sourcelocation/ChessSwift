//
//  ChessLogic.swift
//  Chess
//
//  Created by Матвей Анисович on 4/4/21.
//

import Foundation

class ChessLogic {
    
    var game: ChessGame!
    
    var whiteCanCastle = true
    var blackCanCastle = true
    
    var isWhiteInCheck = false
    var isBlackInCheck = false
    
    
    // MARK: Get moves for x and y without checking for "Check"
    private func movesFor(pos: Pos, lastMove:NormalMove?, with board: [[ChessPiece?]]) -> [NormalMove] {
        let x = pos.x
        let y = pos.y
        
        
        guard let piece = board[y][x] else { return [] }
        
        let color = piece.pieceColor
        let type = piece.pieceType
        
        var moves: [NormalMove] = []
        
        let dir = color == .white ? 1 : -1
        
        if type == .pawn { // MARK: - Pawn -
            if y - dir <= 7, y - dir >= 0 {
                // 1 forward
                if board[y - dir][x] == nil {
                    moves.append(NormalMove(from: pos, to: Pos(x:x, y:y - dir)))
                    // 2 forward
                    if y == (color == .white ? 6 : 1), board[y - 2 * dir][x] == nil {
                        moves.append(NormalMove(from: pos, to: Pos(x:x, y:y - (2 * dir)), doublePawnMove: true))
                    }
                }
                // Diagonal
                if x > 0 { // Left
                    if board[y - dir][x - 1] != nil, board[y - dir][x - 1]?.pieceColor != color {
                        moves.append(NormalMove(from: pos, to: Pos(x: x - 1, y:y - dir)))
                    } else if lastMove?.doublePawnMove ?? false, lastMove?.toPos?.y == y, lastMove?.toPos?.x == x - 1 {
                        moves.append(NormalMove(from: pos, to: Pos(x: x - 1, y:y - dir),additionalMove: DestroyMove(pos: Pos(x: x - 1, y: y))))
                    }
                }
                if x < 7 { // Right
                    if board[y - dir][x + 1] != nil, board[y - dir][x + 1]?.pieceColor != color {
                        moves.append(NormalMove(from: pos, to: Pos(x: x + 1, y:y - dir)))
                    } else if lastMove?.doublePawnMove ?? false, lastMove?.toPos?.y == y, lastMove?.toPos?.x == x + 1 {
                        moves.append(NormalMove(from: pos, to: Pos(x: x + 1, y:y - dir),additionalMove: DestroyMove(pos: Pos(x: x + 1, y: y))))
                    }
                }
            }
        } else if type == .knight { // MARK: - Knight -
            let avaliableMoves = [(y - 2,x - 1),(y + 2,x - 1),(y + 1,x - 2),(y - 1,x - 2),(y + 2,x + 1),(y - 2,x + 1),(y - 1,x + 2),(y + 1,x + 2)]
            for move in avaliableMoves {
                if move.0 > board.count - 1 { continue }
                if move.0 < 0 { continue }
                if move.1 > board[move.0].count - 1 { continue }
                if move.1 < 0 { continue }
                let piece = board[move.0][move.1]
                if piece?.pieceColor == color {
                    continue
                } else {
                    moves.append(NormalMove(from: pos, to: Pos(x: move.1, y: move.0)))
                }
            }
        } else if type == .king { // MARK: - King -
            for x1 in x-1...x+1 {
                for y1 in y-1...y+1 {
                    if y1 > board.count - 1 { continue }
                    if y1 < 0 { continue }
                    if x1 > board[y1].count - 1 { continue }
                    if x1 < 0 { continue }
                    if board[y1][x1] == nil || board[y1][x1]?.pieceColor != color {
                        moves.append(NormalMove(from: pos, to: Pos(x: x1, y: y1)))
                    }
                }
            }
            // MARK: King castling
            if color == .white, whiteCanCastle, !isWhiteInCheck {
                if board[7][7] != nil, board[7][7]!.pieceType == .rook {
                    if board[7][6] == nil, board[7][5] == nil {
                        // MARK: Битое поле
                        if !checkCheckIfChessPiece(willMoveFrom: Pos(x: x, y: y), to: Pos(x:5, y:7), board: board), !checkCheckIfChessPiece(willMoveFrom: Pos(x:x, y:y), to: Pos(x:6, y:7), board: board) {
                            moves.append(NormalMove(from: pos, to: Pos(x:6, y:7), additionalMove: NormalMove(from: Pos(x: 7, y: 7), to: Pos(x: 5, y: 7))))
                        }
                        
                    }
                }
                if board[7][0] != nil, board[7][0]!.pieceType == .rook {
                    if board[7][1] == nil, board[7][2] == nil, board[7][3] == nil {
                        // Битое поле
                        if !checkCheckIfChessPiece(willMoveFrom: Pos(x: x, y: y), to: Pos(x: 3, y: 7), board: board), !checkCheckIfChessPiece(willMoveFrom: Pos(x: x, y: y), to: Pos(x: 2, y: 7), board: board) {
                            moves.append(NormalMove(from: pos, to: Pos(x:2, y:7), additionalMove: NormalMove(from: Pos(x: 0, y: 7), to: Pos(x: 3, y: 7))))
                        }
                    }
                }
            }
            if color == .black, blackCanCastle, !isBlackInCheck {
                if board[0][7] != nil, board[0][7]!.pieceType == .rook {
                    if board[0][6] == nil, board[0][5] == nil {
                        // Битое поле
                        if !checkCheckIfChessPiece(willMoveFrom: Pos(x: x, y: y), to: Pos(x: 5, y: 0), board: board), !checkCheckIfChessPiece(willMoveFrom: Pos(x: x, y: y), to: Pos(x: 6, y: 0), board: board) {
                            moves.append(NormalMove(from: pos, to: Pos(x:6, y: 0), additionalMove: NormalMove(from: Pos(x: 7, y: 0), to: Pos(x: 5, y: 0))))
                        }
                    }
                }
                if board[0][0] != nil, board[0][0]!.pieceType == .rook {
                    if board[0][1] == nil, board[0][2] == nil, board[0][3] == nil {
                        // Битое поле
                        if !checkCheckIfChessPiece(willMoveFrom: Pos(x: x, y: y), to: Pos(x: 3, y: 0), board: board), !checkCheckIfChessPiece(willMoveFrom: Pos(x: x, y: y), to: Pos(x: 2, y: 0), board: board) {
                            moves.append(NormalMove(from: pos, to: Pos(x:2, y:0), additionalMove: NormalMove(from: Pos(x: 0, y: 0), to: Pos(x: 3, y: 0))))
                        }
                    }
                }
            }
        } else if type == .rook { //MARK: - Rook -
            var xToCheck = x
            var yToCheck = y
            
            while xToCheck <= 7 {
                // MARK: Right
                if board[yToCheck][xToCheck]?.pieceColor == color {
                    if xToCheck != x || yToCheck != y {
                        break
                    }
                } else {
                    moves.append(NormalMove(from: pos, to: Pos(x: xToCheck, y: yToCheck)))
                }
                if board[yToCheck][xToCheck] != nil, board[yToCheck][xToCheck]?.pieceColor != color {
                    break
                }
                xToCheck += 1
            }
            xToCheck = x
            while xToCheck >= 0 {
                // MARK: Left
                if board[yToCheck][xToCheck]?.pieceColor == color {
                    if xToCheck != x || yToCheck != y {
                        break
                    }
                } else {
                    moves.append(NormalMove(from: pos, to: Pos(x: xToCheck, y: yToCheck)))
                }
                if board[yToCheck][xToCheck] != nil, board[yToCheck][xToCheck]?.pieceColor != color {
                    break
                }
                xToCheck -= 1
            }
            xToCheck = x
            while yToCheck >= 0 {
                //MARK: Down
                if board[yToCheck][xToCheck]?.pieceColor == color {
                    if xToCheck != x || yToCheck != y {
                        break
                    }
                } else {
                    moves.append(NormalMove(from: pos, to: Pos(x: xToCheck, y: yToCheck)))
                }
                if board[yToCheck][xToCheck] != nil, board[yToCheck][xToCheck]?.pieceColor != color {
                    break
                }
                yToCheck -= 1
            }
            yToCheck = y
            while yToCheck <= 7 {
                // MARK: Up
                if board[yToCheck][xToCheck]?.pieceColor == color {
                    if xToCheck != x || yToCheck != y {
                        break
                    }
                } else {
                    moves.append(NormalMove(from: pos, to: Pos(x: xToCheck, y: yToCheck)))
                }
                if board[yToCheck][xToCheck] != nil, board[yToCheck][xToCheck]?.pieceColor != color {
                    break
                }
                yToCheck += 1
            }
        } else if type == .bishop { // MARK: - Bishop -
            var xToCheck = x
            var yToCheck = y
            
            while xToCheck <= 7,yToCheck >= 0 {
                // MARK: Right up
                if board[yToCheck][xToCheck]?.pieceColor == color {
                    if xToCheck != x || yToCheck != y {
                        break
                    }
                } else {
                    moves.append(NormalMove(from: pos, to: Pos(x: xToCheck, y: yToCheck)))
                }
                if board[yToCheck][xToCheck] != nil, board[yToCheck][xToCheck]?.pieceColor != color  {
                    break
                }
                xToCheck += 1
                yToCheck -= 1
            }
            xToCheck = x
            yToCheck = y
            while xToCheck >= 0, yToCheck >= 0 {
                // MARK: Left up
                if board[yToCheck][xToCheck]?.pieceColor == color {
                    if xToCheck != x || yToCheck != y {
                        break
                    }
                } else {
                    moves.append(NormalMove(from: pos, to: Pos(x: xToCheck, y: yToCheck)))
                }
                if board[yToCheck][xToCheck] != nil, board[yToCheck][xToCheck]?.pieceColor != color {
                    break
                }
                xToCheck -= 1
                yToCheck -= 1
            }
            xToCheck = x
            yToCheck = y
            while xToCheck <= 7, yToCheck <= 7 {
                // MARK: Down right
                if board[yToCheck][xToCheck]?.pieceColor == color {
                    if xToCheck != x || yToCheck != y {
                        break
                    }
                } else {
                    moves.append(NormalMove(from: pos, to: Pos(x: xToCheck, y: yToCheck)))
                }
                if board[yToCheck][xToCheck] != nil, board[yToCheck][xToCheck]?.pieceColor != color {
                    break
                }
                yToCheck += 1
                xToCheck += 1
            }
            xToCheck = x
            yToCheck = y
            while xToCheck >= 0, yToCheck <= 7 {
                // MARK: Down left
                if board[yToCheck][xToCheck]?.pieceColor == color {
                    if xToCheck != x || yToCheck != y {
                        break
                    }
                } else {
                    moves.append(NormalMove(from: pos, to: Pos(x: xToCheck, y: yToCheck)))
                }
                if board[yToCheck][xToCheck] != nil, board[yToCheck][xToCheck]?.pieceColor != color {
                    break
                }
                xToCheck -= 1
                yToCheck += 1
            }
        } else if type == .queen { // MARK: - Queen -
            // Combination of rook and bishop
            board[y][x]!.pieceType = .rook
            moves += movesFor(pos: pos, lastMove: lastMove, with: board)
            board[y][x]!.pieceType = .bishop
            moves += movesFor(pos: pos, lastMove: lastMove, with: board)
            // Change back to queen
            board[y][x]!.pieceType = .queen
        }
        
        
        return moves
    }
    
    func checkCheck(board:[[ChessPiece?]]) {
        if checkCheck(for: .white, board: board) {
            isWhiteInCheck = true
        }
        if checkCheck(for: .black, board: board) {
            isBlackInCheck = true
        }
    }
    
    // MARK: Moves with checking for "Checks"
    func getMoves(pos: Pos, lastMove: NormalMove?, board: [[ChessPiece?]]) -> [NormalMove] {
        checkCheck(board: board)
        let nonCheckedMoves = movesFor(pos: pos, lastMove: lastMove, with: board)
        var moves:[NormalMove] = []
        for move in nonCheckedMoves {
            var testBoard = board
            
            let piece = testBoard[pos.y][pos.x]
            let color = piece?.pieceColor
            
//            print("Moving \(piece!.pieceType)")
            testBoard[move.toPos!.y][move.toPos!.x] = nil
            testBoard[pos.y][pos.x] = nil
            testBoard[move.toPos!.y][move.toPos!.x] = piece
            
//            game.delegate?.uiMove(piece: piece!, to: move.toPos, withSound: true)
            
            if let color = color {
                if !checkCheck(for: color, board: testBoard) {
                    moves.append(move)
                }
            }
        }
        
        return moves
    }
    
    // MARK: Function to check "Checks"
    func checkCheck(for color: ChessPieceColor, board: [[ChessPiece?]]) -> Bool {
        guard let kingPos = kingPos(color: color, board: board) else { return true }
        
        for (y,row) in board.enumerated() {
            for (x,_) in row.enumerated() {
                // Битое поле fix
                if Pos(x: x, y: y) == kingPos || Pos(x: x, y: y) == self.kingPos(color: color.inverted, board: board) {
                    if color == .white ? whiteCanCastle : blackCanCastle { continue }
                }
                // Fixes hundreds of crashes
                if let piece = board[y][x], piece.pieceColor != color {
//                    print(y,x,piece.pieceColor,piece.pieceType)
                    let moves = movesFor(pos: Pos(x: x, y: y), lastMove: nil, with: board)
                    if moves.contains(where: { pos1 in
                        return pos1.toPos?.x == kingPos.x && pos1.toPos?.y == kingPos.y
                    }) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    // MARK:Checkmate check
    func checkCheckmate(for color: ChessPieceColor, lastMove: NormalMove?, board: [[ChessPiece?]]) -> Bool {
        for (y,row) in board.enumerated() {
            for (x,_) in row.enumerated() {
                if board[y][x]?.pieceColor == color {
                    let moves = getMoves(pos:Pos(x: x, y: y), lastMove: lastMove, board: board)
                    if moves.count > 0 {
                        return false
                    }
                }
            }
        }
        return true
    }
    func checkCheckIfChessPiece(willMoveFrom pos1: Pos, to pos2: Pos, board: [[ChessPiece?]]) -> Bool {
        var testBoard = board
        let piece = testBoard[pos1.y][pos1.x]
        testBoard[pos1.y][pos1.x] = nil
        testBoard[pos2.y][pos2.x] = nil
        testBoard[pos2.y][pos2.x] = piece
        
        return checkCheck(for: piece!.pieceColor, board: testBoard)
    }
    func kingPos(color: ChessPieceColor, board: [[ChessPiece?]]) -> Pos? {
        for y in 0...7 {
            for x in 0...7 {
                if board[y][x]?.pieceType == .king, board[y][x]!.pieceColor == color {
                    return Pos(x: x, y: y)
                }
            }
        }
        return nil
    }
    func printBoard(_ board: [[ChessPiece?]]) {
        board.forEach { row in
            print(row.map { piece -> String in
                guard let piece = piece else { return "None" }
                return (piece.pieceColor.rawValue + piece.pieceType.rawValue)
            }.joined(separator: " "))
        }
    }
    
}
