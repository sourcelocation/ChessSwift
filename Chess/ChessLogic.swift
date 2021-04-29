//
//  ChessLogic.swift
//  Chess
//
//  Created by Матвей Анисович on 4/4/21.
//

import Foundation

class ChessLogic {
    
    var whiteCanCastle = true
    var blackCanCastle = true
    
    var isWhiteInCheck = false
    var isBlackInCheck = false
    
    
    // MARK: Get moves for x and y without checking for "Check"
    func movesFor(x:Int,y:Int, lastMove:Move?, with board: [[ChessPiece?]]) -> [(Int,Int)] {
        guard let piece = board[y][x] else { return [] }
        let color = piece.pieceColor
        let type = piece.pieceType
        
        var moves: [(Int,Int)] = []
        
        let dir = color == .white ? 1 : -1
        
        if type == .pawn { // MARK: - Pawn -
            if y - dir <= 7, y - dir >= 0 {
                // 1 forward
                if board[y - dir][x] == nil {
                    moves.append((y - dir, x))
                    // 2 forward
                    if y == (color == .white ? 6 : 1), board[y - 2 * dir][x] == nil {
                        moves.append((y - (2 * dir), x))
                    }
                }
                // Diagonal
                if x > 0 { // Left
                    if board[y - dir][x - 1] != nil, board[y - dir][x - 1]?.pieceColor != color {
                        moves.append((y - dir, x - 1))
                    } else if lastMove?.doublePawnMove ?? false, lastMove?.toY == y, lastMove?.toX == x - 1 {
                        moves.append((y - dir, x - 1))
                    }
                }
                if x < 7 { // Right
                    if board[y - dir][x + 1] != nil, board[y - dir][x + 1]?.pieceColor != color {
                        moves.append((y - dir, x + 1))
                    } else if lastMove?.doublePawnMove ?? false, lastMove?.toY == y, lastMove?.toX == x + 1 {
                        moves.append((y - dir, x + 1))
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
                    moves.append(move)
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
                        // TODO: Check if came near other king
                        moves.append((y1,x1))
                    }
                }
            }
            // MARK: King castling
            if color == .white, whiteCanCastle, !isWhiteInCheck {
                if board[7][7] != nil, board[7][7]!.pieceType == .rook {
                    if board[7][6] == nil, board[7][5] == nil {
                        // MARK: Битое поле
                        if !checkCheckIfChessPiece(willMoveFrom: (y,x), to: (7,5), board: board), !checkCheckIfChessPiece(willMoveFrom: (y,x), to: (7,6), board: board) {
                            moves.append((7,6))
                        }
                        
                    }
                }
                if board[7][0] != nil, board[7][0]!.pieceType == .rook {
                    if board[7][1] == nil, board[7][2] == nil, board[7][3] == nil {
                        // Битое поле
                        if !checkCheckIfChessPiece(willMoveFrom: (y,x), to: (7,3), board: board), !checkCheckIfChessPiece(willMoveFrom: (y,x), to: (7,2), board: board), !checkCheckIfChessPiece(willMoveFrom: (y,x), to: (7,1), board: board) {
                            moves.append((7,2))
                        }
                    }
                }
            }
            if color == .black, blackCanCastle, !isBlackInCheck {
                if board[0][7] != nil, board[0][7]!.pieceType == .rook {
                    if board[0][6] == nil, board[0][5] == nil {
                        // Битое поле
                        if !checkCheckIfChessPiece(willMoveFrom: (y,x), to: (0,5), board: board), !checkCheckIfChessPiece(willMoveFrom: (y,x), to: (0,6), board: board) {
                            moves.append((0,6))
                        }
                    }
                }
                if board[0][0] != nil, board[0][0]!.pieceType == .rook {
                    if board[0][1] == nil, board[0][2] == nil, board[0][3] == nil {
                        // Битое поле
                        if !checkCheckIfChessPiece(willMoveFrom: (y,x), to: (0,3), board: board), !checkCheckIfChessPiece(willMoveFrom: (y,x), to: (0,2), board: board), !checkCheckIfChessPiece(willMoveFrom: (y,x), to: (0,1), board: board) {
                            moves.append((0,2))
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
                    moves.append((yToCheck,xToCheck))
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
                    moves.append((yToCheck,xToCheck))
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
                    moves.append((yToCheck,xToCheck))
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
                    moves.append((yToCheck,xToCheck))
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
                    moves.append((yToCheck,xToCheck))
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
                    moves.append((yToCheck,xToCheck))
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
                    moves.append((yToCheck,xToCheck))
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
                    moves.append((yToCheck,xToCheck))
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
            moves += movesFor(x: x, y: y, lastMove: lastMove, with: board)
            board[y][x]!.pieceType = .bishop
            moves += movesFor(x: x, y: y, lastMove: lastMove, with: board)
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
    func getMoves(x:Int,y:Int,lastMove:Move?,with board: [[ChessPiece?]]) -> [(Int,Int)] {
        checkCheck(board: board)
        let nonCheckedMoves = movesFor(x: x, y: y, lastMove: lastMove, with: board)
        var moves:[(Int,Int)] = []
        for move in nonCheckedMoves {
            var testBoard = board
            
            let piece = testBoard[y][x]
            let color = piece?.pieceColor
            
            testBoard[move.0][move.1] = nil
            testBoard[y][x] = nil
            testBoard[move.0][move.1] = piece
            
            if color != nil {
                if !checkCheck(for: color!, board: testBoard) {
                    moves.append(move)
                }
            }
        }
        
        return moves
    }
    
    // MARK: Function to check "Checks"
    func checkCheck(for color: ChessPieceColor, board: [[ChessPiece?]]) -> Bool {
        var kingPos: (Int,Int)?
        for x in 0...7 {
            for y in 0...7 {
                if board[y][x]?.pieceType == .king, board[y][x]!.pieceColor == color {
                    kingPos = (y,x)
                }
            }
        }
        if kingPos == nil {
            return true
        }
        for (y,row) in board.enumerated() {
            for (x,_) in row.enumerated() {
                if board[y][x]?.pieceColor != color {
                    let moves = movesFor(x: x, y: y, lastMove: nil, with: board)
                    if moves.contains(kingPos!) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    // MARK:Checkmate check
    func checkCheckmate(for color: ChessPieceColor, lastMove: Move?, board: [[ChessPiece?]]) -> Bool {
        for (y,row) in board.enumerated() {
            for (x,_) in row.enumerated() {
                if board[y][x]?.pieceColor == color {
                    let moves = getMoves(x: x, y: y, lastMove: lastMove, with: board)
                    if moves.count > 0 {
                        return false
                    }
                }
            }
        }
        return true
    }
    func checkCheckIfChessPiece(willMoveFrom pos1: (Int,Int), to pos2: (Int,Int), board: [[ChessPiece?]]) -> Bool {
        var testBoard = board
        let piece = testBoard[pos1.0][pos1.1]
        testBoard[pos1.0][pos1.1] = nil
        testBoard[pos2.0][pos2.1] = nil
        testBoard[pos2.0][pos2.1] = piece
        
        return checkCheck(for: piece!.pieceColor, board: testBoard)
    }
}
