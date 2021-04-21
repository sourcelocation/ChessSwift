//
//  GameScene.swift
//  Chess
//
//  Created by Матвей Анисович on 4/4/21.
//

import SpriteKit
import GameplayKit


class GameScene: SKScene {
    
    var chessLogic = ChessLogic()
    var board: SKShapeNode!
    
    var history: [Move] = []
    
    var boardPieces:[[ChessPiece?]] = []
    var cells: [[SKShapeNode]] = []
    var turnOf: ChessPieceColor = .white
    var isMovingPiece = false
    
    var turnCells: SKSpriteNode!
    var freeMode = false
    
    var selectedCell: (Int,Int)? = nil
    var movesForSelectedCell: [(Int,Int)]? = nil
    
    // SFX
    let checkmateSound: SKAction = .playSoundFileNamed("CheckSound3.wav", waitForCompletion: false)
    let piecePlaceSound: SKAction = .playSoundFileNamed("ChessPiecePlace.wav", waitForCompletion: false)
    let checkSound: SKAction = .playSoundFileNamed("CheckSound2.wav", waitForCompletion: false)
    
    fileprivate func loadSaveGameData() {
        if let historyData = UserDefaults.standard.data(forKey: "history") {
            chessLogic.whiteCanCastle = UserDefaults.standard.bool(forKey: "whiteCanCastle")
            chessLogic.blackCanCastle = UserDefaults.standard.bool(forKey: "blackCanCastle")
            chessLogic.isWhiteInCheck = UserDefaults.standard.bool(forKey: "isWhiteInCheck")
            chessLogic.isBlackInCheck = UserDefaults.standard.bool(forKey: "isBlackInCheck")
            
            history = try! JSONDecoder().decode([Move].self, from: historyData)
            turnOf = (history.count - (chessLogic.whiteCanCastle ? 0 : 1) - (chessLogic.blackCanCastle ? 0 : 1)) % 2 == 0 ? .white : .black
            jumpToMove(history.count - 1)
        }
    }
    
    override func sceneDidLoad() {
        resetBoard()
        createBoard()
        createLetters()
        
        // Gray dots layer
        turnCells = SKSpriteNode(color: .clear, size: UIScreen.main.bounds.size)
        turnCells.zPosition = 1
        addChild(turnCells)
        
        createButtons()
        
        loadSaveGameData()
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        
    }
    
    fileprivate func resetSelectedCell() {
        selectedCell = nil
        self.movesForSelectedCell = nil
        resetCellColors()
    }
    
    fileprivate func selectCell(_ x: Int, _ y: Int) {
        resetCellColors()
        
        if !freeMode {
            movesForSelectedCell = chessLogic.getMoves(x: x, y: y, with: boardPieces)
            // Creating gray dots
            let spacing = (board.frame.width - 60) / 8
            for move in movesForSelectedCell! {
                // Gray dots
                let cell = SKShapeNode(rectOf: CGSize(width: spacing, height: spacing))
                var circle = SKShapeNode()
                cell.lineWidth = 0
                cell.position = positionInBoard(x: move.1, y: move.0)
                if boardPieces[move.0][move.1] == nil {
                    // Empty cell
                    circle = SKShapeNode(ellipseOf: CGSize(width: spacing / 3, height: spacing / 3))
                    circle.lineWidth = 0
                    circle.fillColor = .init(white: 0.4, alpha: 0.15)
                } else {
                    // Occupied cell
                    circle = SKShapeNode(ellipseOf: CGSize(width: spacing - 7, height: spacing - 7))
                    circle.lineWidth = 14
                    circle.strokeColor = .init(white: 0.4, alpha: 0.15)
                }
                
                cell.name = "cell"
                circle.name = "circle"
                turnCells.addChild(cell)
                cell.addChild(circle)
            }
            // Cannot move, show red square
            if movesForSelectedCell!.count == 0 {
                cells[selectedCell!.0][selectedCell!.1].fillColor = .init(red: 1, green: 129 / 255, blue: 123 / 255, alpha: 1)
            }
        } else if freeMode {
            // Green Cell
            cells[selectedCell!.0][selectedCell!.1].fillColor = .init(red: 160 / 255, green: 238 / 255, blue: 160 / 255, alpha: 1)
        }
    }
    
    fileprivate func moveSelectedPieceToPosition(_ y: Int, _ x: Int) {
        // Move piece
        let piece = boardPieces[selectedCell!.0][selectedCell!.1]
        if boardPieces[y][x]?.pieceType == .king {
            self.selectedCell = nil
            self.movesForSelectedCell = nil
            return
        }
        var destPos = positionInBoard(x: x, y: y)
        
        // Image offset for decoration
        if piece?.pieceType == .pawn {
            destPos.y += (piece!.pieceColor == .white) ? 5 : -5
        }
        
        isMovingPiece = true
        chessLogic.isWhiteInCheck = false
        chessLogic.isBlackInCheck = false
        
        var castling = false
        
        piece?.run(.move(to: destPos, duration: 0.2))
        piece?.run(.sequence([.wait(forDuration: 0.2),.run {
            self.movePiece(x1: self.selectedCell!.1, y1: self.selectedCell!.0, x2: x, y2: y, turnTo: nil, isCastling: castling)
            
            self.selectedCell = nil
            self.movesForSelectedCell = nil
            
            // MARK: Pawn to queen
            if piece?.pieceType == .pawn {
                if self.positionInBoardAtPos(piece!.position).1 == (piece!.pieceColor == .white ? 0 : 7) {
                    let alert = UIAlertController(title: "Piece selection", message: "", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Queen", style: .default, handler: { _ in
                        piece?.pieceType = .queen
                        let imageName = piece!.pieceType.rawValue + "-" + piece!.pieceColor.rawValue
                        let texture = SKTexture(imageNamed: imageName)
                        piece?.texture = texture
                        piece?.position = self.positionInBoard(x: x, y: y)
                        self.afterMoveHandling(forPiece: piece!)
                        self.history[self.history.count - 1].turnedTo = .queen
                    }))
                    alert.addAction(UIAlertAction(title: "Knight", style: .default, handler: { _ in
                        piece?.pieceType = .knight
                        let imageName = piece!.pieceType.rawValue + "-" + piece!.pieceColor.rawValue
                        let texture = SKTexture(imageNamed: imageName)
                        piece?.texture = texture
                        piece?.position = self.positionInBoard(x: x, y: y)
                        self.afterMoveHandling(forPiece: piece!)
                        self.history[self.history.count - 1].turnedTo = .knight
                    }))
                    alert.addAction(UIAlertAction(title: "Bishop", style: .default, handler: { _ in
                        piece?.pieceType = .bishop
                        let imageName = piece!.pieceType.rawValue + "-" + piece!.pieceColor.rawValue
                        let texture = SKTexture(imageNamed: imageName)
                        piece?.texture = texture
                        piece?.position = self.positionInBoard(x: x, y: y)
                        self.afterMoveHandling(forPiece: piece!)
                        self.history[self.history.count - 1].turnedTo = .bishop
                    }))
                    alert.addAction(UIAlertAction(title: "Rook", style: .default, handler: { _ in
                        piece?.pieceType = .rook
                        let imageName = piece!.pieceType.rawValue + "-" + piece!.pieceColor.rawValue
                        let texture = SKTexture(imageNamed: imageName)
                        piece?.texture = texture
                        piece?.position = self.positionInBoard(x: x, y: y)
                        self.afterMoveHandling(forPiece: piece!)
                        self.history[self.history.count - 1].turnedTo = .rook
                    }))
                    self.view?.window?.rootViewController?.present(alert, animated: true)
                }
            }
            
            self.afterMoveHandling(forPiece: piece!)
            
            self.isMovingPiece = false
        }]))
        
        
        // Hardcoding all positions
        if piece?.pieceType == .king {  // MARK: Castling
            if piece?.pieceColor == .white { // Can not castle after move
                chessLogic.whiteCanCastle = false
            } else {
                chessLogic.blackCanCastle = false
            }
            if x == 6, y == (piece?.pieceColor == .white ? 7 : 0) {
                if self.selectedCell!.0 == (piece?.pieceColor == .white ? 7 : 0) {
                    if self.selectedCell!.1 == 4 {
                        guard let rook = boardPieces[(piece?.pieceColor == .white ? 7 : 0)][7] else { return }
                        
                        castling = true
                        
                        let positionToMoveTo = positionInBoard(x: 5, y: (piece?.pieceColor == .white ? 7 : 0))
                        rook.run(.move(to: positionToMoveTo, duration: 0.2))
                        rook.run(.sequence([.wait(forDuration: 0.2),.run {
                            self.movePiece(x1: 7, y1: (piece?.pieceColor == .white ? 7 : 0), x2: 5, y2: (piece?.pieceColor == .white ? 7 : 0), turnTo: nil, isCastling: false)
                            self.afterMoveHandling(forPiece: piece!)
                        }]))
                    }
                }
            }
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        let node = atPoint(pos)
        
        var (x,y) = positionInBoardAtPos(pos)
        
        if selectedCell?.1 == x, selectedCell?.0 == y {
            resetSelectedCell()
            return
        }
        
        if node.name == "backButton" {
            if history.count > 0 {
                run(piecePlaceSound)
                jumpToMove(history.count - 2)
                saveHistory()
            }
        } else if node.name == "resetButton" {
            showResetAlert()
        }
        
        if isMovingPiece { return }
        if let piece = atPoint(pos) as? ChessPiece {
            // Get location of piece, shoud use my own function
            var (x,y): (Int,Int) = (0,0)
            for row in boardPieces {
                guard let i = row.firstIndex(of: piece) else { continue }
                x = i
                y = boardPieces.firstIndex(of: row)!
            }
            if selectedCell == nil || !movesContains((x,y)) {
                // MARK: Select piece
                if piece.pieceColor != turnOf, !freeMode { resetCellColors(); return }
                selectedCell = (y,x)
                
                selectCell(x, y)
                return
            }
        }
        
        // MARK: "Move to selected cell"
        let cell = atPoint(pos)
        let piece = atPoint(pos) as? ChessPiece
        if piece == nil, cell.name != "cell", cell.name != "circle" {
            if !freeMode {
                resetCellColors()
                self.selectedCell = nil
                self.movesForSelectedCell = nil
                return
            }
        }
        
        // Location on board of clicked cell
        if cell.name == "circle" {
            (x,y) = positionInBoardAtPos(convert(cell.position, from: cell))
        } else if freeMode {
            (x,y) = positionInBoardAtPos(pos)
            if selectedCell?.1 == x, selectedCell?.0 == y {
                resetCellColors(); return
            }
            if x < 0 || x > 7 {
                resetCellColors(); return
            }
            if y < 0 || y > 7 {
                resetCellColors(); return
            }
        } else {
            (x,y) = positionInBoardAtPos(cell.position)
        }
        
        if selectedCell != nil {
            resetCellColors(removeCheckmateCell: true)
            if freeMode || movesContains((x,y)) {
                moveSelectedPieceToPosition(y, x)
            } else {
                if !isMovingPiece {
                    self.selectedCell = nil
                    self.movesForSelectedCell = nil
                }
            }
            
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        
    }
    
    func afterMoveHandling(forPiece piece: ChessPiece) {
        // MARK: Checkmate check
        let isCheckmate = self.chessLogic.checkCheckmate(for: self.turnOf, board: self.boardPieces)
        if isCheckmate {
            piece.run(self.checkmateSound)
            self.showCheckmateAlert(for: self.turnOf)
        }
        
        // MARK: Red color under king when "checking"
        
        if self.chessLogic.isWhiteInCheck || self.chessLogic.isBlackInCheck { // isWhiteInCheck is set and handled in "ChessLogic.swift"
            
            self.addRedCellUnderKing()
            
            // MARK: SFX
            // Check sound
            if !isCheckmate {
                piece.run(self.checkSound)
            }
        } else {
            piece.run(self.piecePlaceSound)
        }
    }
    
    func createBoard() {
        let sizeOfBoard = UIScreen.main.bounds.width > UIScreen.main.bounds.height ? (UIScreen.main.bounds.height - 100) : (UIScreen.main.bounds.width - 100)
        
        board = SKShapeNode(rect: CGRect(x: -sizeOfBoard / 2, y: -sizeOfBoard / 2, width: sizeOfBoard, height: sizeOfBoard), cornerRadius: 1)
        board.strokeColor = .init(red: 104 / 255, green: 69 / 255, blue: 41 / 255, alpha: 1.0)
        board.lineWidth = 30
        board.fillColor = .init(white: 0.9, alpha: 1)
        addChild(board)
        
        // Grid
        let grid = SKSpriteNode(color: .clear, size: board.frame.size)
        let spacing = (board.frame.width - 60) / 8
        let halfSpacing = spacing / 2
        addChild(grid)
        
        createPieces()
        
        for i1 in 0...7 {
            cells.append([])
            for i2 in 0...7 {
                
                var pos = positionInBoard(x: i2, y: i1)
                pos.x -= halfSpacing
                pos.y -= halfSpacing
                
                // MARK: Checkerboard
                let square = SKShapeNode(rect: CGRect(origin: .zero, size: CGSize(width: spacing, height: spacing)))
                if (i1 + i2) % 2 == 0 {
                    square.fillColor = .init(white: 0.9, alpha: 1)
                } else {
                    square.fillColor = .init(red: 209 / 256, green: 177 / 256, blue: 135 / 256, alpha: 1)
                }
                square.position = pos
                square.zPosition = 0
                square.lineWidth = 0
                square.name = "cell1"
                grid.addChild(square)
                cells[i1].append(square)
            }
        }
    }
    func createPieces() {
        let spacing = (board.frame.width - 60) / 8
        for i1 in 0...7 {
            for i2 in 0...7 {
                // MARK: Pieces
                if let piece = boardPieces[i1][i2] {
                    piece.position = positionInBoard(x: i2, y: i1)
                    piece.zPosition = 2
                    piece.texture = SKTexture(imageNamed: piece.pieceType.rawValue + "-" + piece.pieceColor.rawValue)
                    
                    if piece.pieceType == .pawn {
                        piece.position.y += (piece.pieceColor == .white) ? 5 : -5
                    }
                    piece.size = CGSize(width: spacing - 10, height: spacing - 10)
                    addChild(piece)
                }
            }
        }
    }
    
    func createLetters() {
        let spacing = (board.frame.width - 60) / 8
        
        for dir in 0...1 {
            for i in 0...7 {
                let characterLabel = SKLabelNode(text: "")
                
                characterLabel.position.y = spacing * CGFloat(i) + board.frame.minY + spacing / 2 + 20
                characterLabel.position.x = board.frame.minX + 15
                if dir == 1 {
                    characterLabel.position.x += board.frame.width - 30
                    characterLabel.position.y += 20
                    characterLabel.zRotation = .pi
                }
                characterLabel.zPosition = 50
                
                let font = UIFont.systemFont(ofSize: 20, weight: .medium)
                
                characterLabel.attributedText = NSAttributedString(string: String(i + 1), attributes: [.font: font, NSAttributedString.Key.foregroundColor: UIColor.init(red: 209 / 256, green: 177 / 256, blue: 135 / 256, alpha: 1)])
                characterLabel.fontColor = .white
                characterLabel.fontSize = 40
                board.addChild(characterLabel)
            }
        }
        for dir in 0...1 {
            for i in 0...7 {
                let characterLabel = SKLabelNode(text: "")
                
                characterLabel.position.x = spacing * CGFloat(i) + board.frame.minX + spacing / 2 + 31
                characterLabel.position.y = board.frame.minY + 8
                if dir == 1 {
                    characterLabel.position.y += board.frame.height - 17
                    characterLabel.zRotation = .pi
                }
                characterLabel.zPosition = 50
                
                let font = UIFont.systemFont(ofSize: 17, weight: .medium)
                
                characterLabel.attributedText = NSAttributedString(string: ["A","B","C","D","E","F","G","H"][i], attributes: [.font: font, NSAttributedString.Key.foregroundColor: UIColor.init(red: 209 / 256, green: 177 / 256, blue: 135 / 256, alpha: 1)])
                characterLabel.fontColor = .white
                characterLabel.fontSize = 40
                board.addChild(characterLabel)
            }
        }
    }
    
    func positionInBoard(x:Int,y:Int) -> CGPoint {
        let startX = (-board.frame.width + 60) / 2.0
        let startY = (board.frame.height - 60) / 2.0
        let spacing = (board.frame.width - 60) / 8
        let halfSpacing = spacing / 2
        return CGPoint(x: startX + spacing * CGFloat(x) + halfSpacing, y: startY - spacing * CGFloat(y) - halfSpacing)
    }
    func positionInBoardAtPos(_ pos:CGPoint) -> (Int,Int) {
        let spacing = (board.frame.width - 60) / 8
        let startX = (-board.frame.width + 60) / 2.0
        let startY = (board.frame.height - 60) / 2.0
        let x = Int((pos.x - startX + 20) / spacing)
        let y = Int((pos.y - startY + 20) / spacing) * -1
        return (x,y)
    }
    func movesContains(_ pos: (Int,Int)) -> Bool {
        if freeMode {
            return true
        }
        // Check if selected cell has provided move.
        return movesForSelectedCell!.contains(where: { (arg0) -> Bool in
            let (x1, y1) = arg0
            return x1 == pos.1 && y1 == pos.0
        })
    }
    func movePiece(x1:Int,y1:Int,x2:Int,y2:Int,turnTo:ChessPieceType?, addToHistory:Bool = true, isCastling: Bool) {
        movePiece(x1: x1, y1: y1, x2: x2, y2: y2,addToHistory: addToHistory)
        
        if turnTo != nil {
            self.boardPieces[y2][x2]?.pieceType = turnTo!
        }
        
        if addToHistory {
            var move = Move(fromX: x1, fromY: y1, toX: x2, toY: y2, turnedTo: turnTo)
            move.isCastling = isCastling
            history.append(move)
            saveHistory()
        }
        // Change turn
        turnOf = (turnOf == .white) ? .black : .white
        if isCastling {
            turnOf = (turnOf == .white) ? .black : .white
        }
    }
    func movePiece(x1:Int,y1:Int,x2:Int,y2:Int, addToHistory:Bool = true) {
        let piece = boardPieces[y1][x1]
        self.boardPieces[y2][x2]?.removeFromParent()
        self.boardPieces[y2][x2] = nil
        self.boardPieces[y1][x1] = nil
        self.boardPieces[y2][x2] = piece
    }
    // MARK: Jump to move
    func jumpToMove(_ i:Int) {
        turnOf = .white
        resetBoard()
        resetCellColors(removeCheckmateCell: true)
        
        var isLastMoveCastlingKingPos: (Int,Int)? = nil
        
        if i != -1 {
            history = Array(history[0...i])
            
            if history.last!.isCastling {
                isLastMoveCastlingKingPos = (history.last!.fromX,history.last!.fromY)
                history = Array(history[0...i - 1])
                
            }
            
            for move in history {
                if move.isCastling {
                    let piece = boardPieces[move.fromY][move.fromX]
                    if piece?.pieceColor == .white {
                        chessLogic.whiteCanCastle = false
                    } else {
                        chessLogic.blackCanCastle = false
                    }
                }
                movePiece(x1: move.fromX, y1: move.fromY, x2: move.toX, y2: move.toY, turnTo: move.turnedTo, addToHistory: false, isCastling: false)
                if isLastMoveCastlingKingPos != nil {
                    let king = boardPieces[isLastMoveCastlingKingPos!.1][isLastMoveCastlingKingPos!.0]
                    if king?.pieceColor == .white {
                        chessLogic.whiteCanCastle = true
                    } else if king?.pieceColor == .black {
                        chessLogic.blackCanCastle = true
                    }
                }
            }
        } else {
            history = []
        }
        chessLogic.checkCheck(board: self.boardPieces)
        if self.chessLogic.isWhiteInCheck || self.chessLogic.isBlackInCheck { // isWhiteInCheck is set and handled in "ChessLogic.swift"
            
            self.addRedCellUnderKing()
            
            // MARK: SFX
            // Check sound
            run(self.checkSound)
        }
        createPieces()
        turnOf = (history.count - (chessLogic.whiteCanCastle ? 0 : 1) - (chessLogic.blackCanCastle ? 0 : 1)) % 2 == 0 ? .white : .black
    }
    
    func resetCellColors(removeCheckmateCell: Bool = false) {
        // Grid tiles
        for (y,row) in cells.enumerated() {
            for (x,cell) in row.enumerated() {
                if (x + y) % 2 == 0 {
                    cell.fillColor = .init(white: 0.9, alpha: 1)
                } else {
                    cell.fillColor = .init(red: 209 / 256, green: 177 / 256, blue: 135 / 256, alpha: 1)
                }
            }
        }
        // Remove "Move" cells
        for cell in turnCells.children {
            if cell.name != "redCell" || removeCheckmateCell {
                cell.removeFromParent()
            }
        }
    }
    func resetBoard() {
        for row in boardPieces {
            for piece in row {
                piece?.removeFromParent()
            }
        }
        boardPieces =
                [
                [.init(pieceColor: .black, pieceType: .rook),.init(pieceColor: .black, pieceType: .knight),.init(pieceColor: .black, pieceType: .bishop),.init(pieceColor: .black, pieceType: .queen),.init(pieceColor: .black, pieceType: .king),.init(pieceColor: .black, pieceType: .bishop),.init(pieceColor: .black, pieceType: .knight),.init(pieceColor: .black, pieceType: .rook)],
                [.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),.init(pieceColor: .black, pieceType: .pawn),],
                [nil,nil,nil,nil,nil,nil,nil,nil],
                [nil,nil,nil,nil,nil,nil,nil,nil],
                [nil,nil,nil,nil,nil,nil,nil,nil],
                [nil,nil,nil,nil,nil,nil,nil,nil],
                [.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn),.init(pieceColor: .white, pieceType: .pawn)],
                 [.init(pieceColor: .white, pieceType: .rook),.init(pieceColor: .white, pieceType: .knight),.init(pieceColor: .white, pieceType: .bishop),.init(pieceColor: .white, pieceType: .queen),.init(pieceColor: .white, pieceType: .king),.init(pieceColor: .white, pieceType: .bishop),.init(pieceColor: .white, pieceType: .knight),.init(pieceColor: .white, pieceType: .rook)]
            ]
        self.chessLogic.isWhiteInCheck = false
        self.chessLogic.isBlackInCheck = false
        chessLogic.whiteCanCastle = true
        chessLogic.blackCanCastle = true
    }
    
    // Unused function, might use it in the future
    func turnAroundPieces() {
        for (y,row) in boardPieces.enumerated() {
            for (x,piece) in row.enumerated() {
                piece?.run(.rotate(toAngle: (turnOf == .white) ? 0 : .pi, duration: 0.1))
                
                if piece?.pieceType == .pawn {
                    piece?.position = positionInBoard(x: x, y: y)
                    piece?.position.y += (turnOf == .white) ? 5 : -5
                }
            }
        }
    }
    func showCheckmateAlert(for color: ChessPieceColor) {
        let tie = color == .white ? !chessLogic.isWhiteInCheck : !chessLogic.isBlackInCheck
        let alert = UIAlertController(title: tie ? "Tie! (No moves)" : ((color == .white) ? "Black wins! (Checkmate)" : "White wins! (Checkmate)"), message: "", preferredStyle: .alert)
        alert.addAction(.init(title: "Close", style: .cancel))
        self.view?.window?.rootViewController?.present(alert, animated: true)
    }
    
    // Create buttons in bottom-right corner
    func createButtons() {
        let brown = UIColor(red: 99 / 255, green: 70 / 255, blue: 49 / 255, alpha: 1.0)
        let widthOfSpaceOnRight = (UIScreen.main.bounds.width - board.frame.width) / 2
        let spacing:CGFloat = 10
        let sizeOfButton = (widthOfSpaceOnRight - spacing * 3) / 2
        
        let button1 = SKShapeNode(rect: CGRect(x: board.frame.maxX + spacing, y: board.frame.minY, width: sizeOfButton, height: sizeOfButton))
        button1.lineWidth = 0
        button1.name = "backButton"
        button1.zPosition = 11
        addChild(button1)
        let image = UIImage(named: "arrow.uturn.backward", in: Bundle.main, with: UIImage.SymbolConfiguration(pointSize: 100,weight: .medium))!.withTintColor(brown, renderingMode: .automatic)
        let texture = SKTexture(image: UIImage(data:image.pngData()!)!)
        
        let button1Image = SKSpriteNode(texture: texture, size: CGSize(width: button1.frame.width - 40, height: button1.frame.height - 45))
        button1.addChild(button1Image)
        button1Image.position = CGPoint(x: board.frame.maxX + spacing + button1.frame.width / 2 - 2, y: board.frame.minY + button1.frame.height / 2 - 2)
        button1Image.name = "backButton"
        button1Image.zPosition = 11
        
        
        let button2 = SKShapeNode(rect: CGRect(x: board.frame.maxX + spacing * 2 + sizeOfButton, y: board.frame.minY, width: sizeOfButton, height: sizeOfButton))
        button2.lineWidth = 0
        button2.name = "resetButton"
        button2.zPosition = 11
        addChild(button2)
        let image2 = UIImage(systemName: "arrow.clockwise", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100,weight: .semibold))!.withTintColor(brown, renderingMode: .automatic)
        let texture2 = SKTexture(image: UIImage(data:image2.pngData()!)!)
        
        let button2Image = SKSpriteNode(texture: texture2, size: CGSize(width: button2.frame.width - 49, height: button2.frame.height - 45))
        button2.addChild(button2Image)
        let twoSpacings = spacing * 2
        let oneAndAHalfSizes = sizeOfButton * 1.5
        button2Image.position = CGPoint(x: board.frame.maxX + twoSpacings + oneAndAHalfSizes - 2, y: board.frame.minY + button2.frame.height / 2 - 2)
        button2Image.name = "resetButton"
        button2Image.zPosition = 11
    }
    // Reset button clicked
    func showResetAlert() {
        let alert = UIAlertController(title: "Start a new game", message: "Are you sure you want to start a new game?", preferredStyle: .alert)
        alert.addAction(.init(title: "Cancel", style: .cancel))
        alert.addAction(.init(title: "Yes", style: .default, handler: { _ in
            self.resetBoard()
            self.createPieces()
            self.turnOf = .white
            self.resetCellColors(removeCheckmateCell: true)
            self.history = []
            UserDefaults.standard.setValue(nil, forKey: "history")
            self.saveHistory()
        }))
        self.view?.window?.rootViewController?.present(alert, animated: true)
    }
    func addRedCellUnderKing() {
        // Change color under king to red
        let kingPos = chessLogic.isWhiteInCheck ? self.kingPos(color: .white) : self.kingPos(color: .black)
        let spacing = (self.board.frame.width - 60) / 8
        let cell = SKSpriteNode(color: .red, size: CGSize(width: spacing, height: spacing)) // cells[move.0][move.1]
        cell.color = .init(red: 1, green: 129 / 255, blue: 123 / 255, alpha: 1)
        cell.position = self.positionInBoard(x: kingPos.1, y: kingPos.0)
        cell.name = "redCell"
        self.turnCells.addChild(cell)
    }
    // Debug function
    func printBoard() -> [[String]] {
        let string = boardPieces.map { $0.map { $0?.pieceType.rawValue ?? "." + ($0?.pieceColor.rawValue ?? ".") }}
        return string
    }
    func kingPos(color:ChessPieceColor) -> (Int,Int) {
        var kingPos: (Int,Int)!
        // Get king position
        for x in 0...7 {
            for y in 0...7 {
                if self.boardPieces[y][x]?.pieceType == .king {
                    if self.boardPieces[y][x]!.pieceColor == color {
                        kingPos = (y,x)
                    } else {
                        continue
                    }
                }
            }
        }
        return kingPos
    }
    func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.setValue(encoded, forKey: "history")
        }
        UserDefaults.standard.setValue(chessLogic.isWhiteInCheck, forKey: "isWhiteInCheck")
        UserDefaults.standard.setValue(chessLogic.isBlackInCheck, forKey: "isBlackInCheck")
        UserDefaults.standard.setValue(chessLogic.whiteCanCastle, forKey: "whiteCanCastle")
        UserDefaults.standard.setValue(chessLogic.blackCanCastle, forKey: "blackCanCastle")
    }
}



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
        
        if pieceColor == .black {
            run(.rotate(toAngle: .pi, duration: 0))
        }
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

struct Move: Codable {
    var fromX: Int
    var fromY: Int
    var toX: Int
    var toY: Int
    var turnedTo: ChessPieceType?
    var isCastling = false
}

enum ChessPieceType: String, Codable {
    case king,queen,rook,bishop,knight,pawn
}

enum ChessPieceColor: String {
    case white,black
}

