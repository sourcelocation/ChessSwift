//
//  ChessTests.swift
//  ChessTests
//
//  Created by exerhythm on 1/2/22.
//

import XCTest
@testable import Chess

class ChessTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPerformance() throws {
        // This is an example of a performance test case.
        measure { //   0.047 - 0.050
            let board: [[ChessPiece?]] =
            [
            [.init(pieceColor: .black, pieceType: .king),nil,nil,nil,nil,nil,nil,nil],
            [nil,nil,nil,nil,nil,nil,.init(pieceColor: .white, pieceType: .rook), .init(.black, .pawn)],
            [nil,nil,nil,nil,.init(.black, .queen),nil,nil,nil],
            [nil,nil,nil,.init(.white, .queen),nil,nil,.init(.white, .pawn),.init(.black, .pawn)],
            [nil,.init(.black, .rook),nil,nil,nil,.init(.black, .knight),nil, nil],
            [nil,nil,nil,.init(.white, .bishop),nil,nil,nil,nil],
            [.init(.white, .pawn),.init(.white, .pawn),nil,nil,nil,nil,nil,.init(.white, .rook)],
            [nil,nil,nil,nil,nil,nil,nil,.init(.white, .king)]
            ]
            var moves:[NormalMove] = []
            let logic = ChessLogic()
            
            for _ in 0...10 {
                for (y,row) in board.enumerated() {
                    for (x,p) in row.enumerated() {
                        if p != nil {
                            moves += logic.getMoves(pos: Pos(x: x, y: y), lastMove: NormalMove(from: Pos(x: 6, y: 6), to: Pos(x: 6, y: 4)), board: board
                            )
                        }
                    }
                }
            }
            
            //            for move in moves {
//                let p = board[move.fromPos.y][move.fromPos.x]!
//                print("\(p.pieceColor) \(p.pieceType) can move to y:\(move.toPos.y) x: \(move.toPos.x)")
//            }
        }
    }

}
