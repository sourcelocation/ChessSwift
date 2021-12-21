//
//  BoardScene.swift
//  Chess
//
//  Created by exerhythm on 7/14/21.
//

import SpriteKit
import SwiftUI

class BoardScene: SKScene {
    
    var online: Bool = false
    
    var game = ChessGame()
    var vcDelegate: GameUIDelegate?
    var vc: GameViewController!
    
    // Sizes
    var boardSize: CGFloat!
    var borderWidth: CGFloat!
    var cellSize: CGFloat!
    var pieceSize: CGSize!
    
    var boardFrame: CGRect {
        return CGRect(x: -boardSize / 2, y: -boardSize / 2, width: boardSize, height: boardSize)
    }
    
    var boardImage: SKSpriteNode?
    var selectedPiece: ChessPiece? {
        get {
            guard let selectedPiecePos = selectedPiecePos else { return nil }
            return game.piece(at: selectedPiecePos)
        }
    }
    var selectedPieceMoves: [NormalMove] = []
    var selectedPiecePos: Pos?
    var isDraggingPiece = false
    
    var draggedPieceFromEditor: ChessPiece?
    
    var didSelectPieceWithTap = false
    var hintsShown = false
    
    var touchPos: CGPoint?
    var moveTouchPos: CGPoint?
    
    var canMove = true // Non-auto timer
    var allowMovesOnlyFromColor: ChessPieceColor?
    
    // Settings
    var showHints: Bool {
        return !UserDefaults.standard.bool(forKey: "showHints")
    }
    var noRules:Bool { return UserDefaults.standard.bool(forKey: "noRules") }
    var proVersion = false
    
    let checkmateSound: SKAction = .playSoundFileNamed("CheckSound3.wav", waitForCompletion: false)
    let piecePlaceSound: SKAction = .playSoundFileNamed("ChessPiecePlace.wav", waitForCompletion: false)
    let checkSound: SKAction = .playSoundFileNamed("CheckSound2.wav", waitForCompletion: false)
    var noSounds: Bool { return UserDefaults.standard.bool(forKey: "noSounds") }
    var noCheckSound: Bool { return UserDefaults.standard.bool(forKey: "noCheckSound") }
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
//        view.allowsTransparency = true
        
        if boardSize == nil {
//            setup()
        }
    }
    
    func setup() {
        game.delegate = self
        
        setUpSizes()
        createBoardImage()
        game.resetBoard(empty: noRules)
        
        run(.repeatForever(.sequence([.run {
            self.proVersion = UserDefaults.standard.bool(forKey: "pro")
        },.wait(forDuration: 2)])))
        
        game.logic.game = game
    }
    
    func setUpSizes() {
        let len = size.height < size.width ? size.height : size.width
        boardSize = 0.93 * len
        borderWidth = 0.035 * len
        cellSize = boardSize / 8
        pieceSize = CGSize(width: cellSize * 0.85, height: cellSize * 0.85)
    }
    
    func touchUp(atPoint loc: CGPoint) {
        self.touchPos = loc
        
        let pieceRef = selectedPiece
        selectedPiece?.run(.sequence([.wait(forDuration: 0.2),.run {
            pieceRef?.zPosition = 1
        }]))
        
        if boardFrame.contains(loc) {
            // Touched a cell
            let cellPos = positionInBoard(at: loc)
            
            if selectedPiecePos != nil {
                if !selectedPieceMoves.contains(where: { $0.toPos == cellPos }) {
                    // Cannot move to dragged cell
                    bringSelectedPieceBack()
                }
            }
            touchedUpBoardCell(at: cellPos)
        } else {
            // Outside of the board
            if noRules {
                if let moveTouchPos = moveTouchPos, !boardFrame.contains(moveTouchPos) {
                    deleteDraggedPiece()
                } else if draggedPieceFromEditor != nil {
                    deleteDraggedPiece()
                }
            } else {
                bringSelectedPieceBack()
            }
        }
        
        if positionInBoard(at: loc) != selectedPiecePos {
            deselectPiece()
        }
        isDraggingPiece = false
        moveTouchPos = nil
    }
    func touchMoved(toPoint loc: CGPoint) {
        self.touchPos = loc
        self.moveTouchPos = loc
        if proVersion {
            if isDraggingPiece || (selectedPiecePos != nil && positionInBoard(at: selectedPiecePos!).distance(to: loc) < cellSize / 2) {
                selectedPiece?.position = loc
                isDraggingPiece = true
            }
        }
        draggedPieceFromEditor?.position = loc
    }
    func touchDown(atPoint loc: CGPoint) {
        self.touchPos = loc
        let boardFrame = CGRect(x: -boardSize / 2, y: -boardSize / 2, width: boardSize, height: boardSize)
        if boardFrame.contains(loc) {
            // Touched a cell
            touchedDownBoardCell(at: positionInBoard(at: loc))
        } else {
            // Touched outside the board
            tappedNode(atPoint(loc))
        }
    }
    
    func touchedDownBoardCell(at pos: Pos) {
        if !canMove { vcDelegate?.bounceTimer(); return }
        removeRedCells(includingCheck: false)
        
        if let piece = game.piece(at: pos) {
            // There is a piece at this position
            
            if piece == selectedPiece && noRules {
                deselectPiece()
            } else if selectedPiece?.pieceColor == piece.pieceColor || selectedPiecePos == nil {
                if piece.pieceColor == game.turnOf || noRules {
                    selectPiece(at: pos)
                }
            }
        }
    }
    func touchedUpBoardCell(at pos: Pos) {
        if let selectedPiece = selectedPiece {
            if game.piece(at: pos)?.pieceColor != selectedPiece.pieceColor {
                // Empty cell
                if let selectedPiecePos = selectedPiecePos {
                    if let move = selectedPieceMoves.first(where: { $0.toPos == pos }) {
                        if selectedPiece.pieceColor == game.turnOf || noRules {
                            perform(move: move)
                        }
                    } else if noRules {
                        let move = NormalMove(from: selectedPiecePos, to: pos)
                        perform(move: move)
                    }
                }
            }
        } else if let draggedPieceFromEditor = draggedPieceFromEditor {
            draggedPieceFromEditor.removeFromParent()
            perform(move: NormalMove(from: pos, to: pos, additionalMove: CreateMove(pos: pos, pieceType: draggedPieceFromEditor.pieceType, pieceColor: draggedPieceFromEditor.pieceColor), doublePawnMove: false))
            self.draggedPieceFromEditor = nil
            game.checkChecks(ui: true)
        }
    }
    
    // MARK: Gameplay
    func perform(move: NormalMove) {
        if game.piece(at: move.toPos)?.pieceType != .king {
            removeRedCells(includingCheck: true)
            resetMoveHints()
            game.perform(move: move, addToHistory: true, uiMove: true, noRules: noRules)
            saveGame()
            vcDelegate?.movedPiece(color: game.piece(at: move.toPos)?.pieceColor ?? .white, move: move)
        } else {
            deselectPiece()
        }
    }
    
    func tappedNode(_ node: SKNode) {
        
    }
    func selectPiece(at pos: Pos) {
        guard let piece = game.piece(at: pos) else { return }
        if allowMovesOnlyFromColor != nil {
            if piece.pieceColor != allowMovesOnlyFromColor { return }
        }
        if allowMovesOnlyFromColor != nil { // Online
            
        }
        selectedPieceMoves = game.moves(for: pos)
        
        resetMoveHints()
        if showHints {
            for move in selectedPieceMoves {
                addMoveCircle(at: move.toPos)
            }
        } else {
            addMoveCircle(at: pos)
        }
        
        if selectedPieceMoves.isEmpty {
            addRedCell(at: pos, check: false)
        }
        selectedPiecePos = pos
        selectedPiece?.zPosition = 3
    }
    func deselectPiece() {
        resetMoveHints()
        selectedPiecePos = nil
    }
    func bringSelectedPieceBack() {
        if let selectedPiecePos = selectedPiecePos {
            selectedPiece?.run(.move(to: positionInBoard(at: selectedPiecePos), duration: 0.15))
        }
    }
    
    func createPieces() {
        for y in 0...7 {
            for x in 0...7 {
                if let piece = game.piece(at: Pos(x: x, y: y)) {
                    piece.position = positionInBoard(at: Pos(x: x, y: y))
                    piece.zPosition = 1
                    piece.size = pieceSize
                    addChild(piece)
                }
            }
        }
    }
    func removePieces() {
        removeRedCells(includingCheck: true) 
        for row in game.board {
            for piece in row {
                piece?.removeFromParent()
            }
        }
    }
    
    fileprivate func resetMoveHints() {
        children.filter { $0.name == "MoveCircle" }.forEach { $0.removeFromParent() }
        hintsShown = false
        removeRedCells(includingCheck: false)
    }
    
    private func addRedCell(at pos: Pos, check: Bool) {
        let cellPosition = positionInBoard(at: pos)
        let redCell = SKShapeNode(rect: CGRect(x: cellPosition.x - cellSize / 2, y: cellPosition.y - cellSize / 2, width: cellSize, height: cellSize))
        redCell.fillColor = .init(red: 1, green: 0.5058, blue: 0.4823, alpha: 1)
        redCell.zPosition = 0.9
        redCell.lineWidth = 0
        redCell.name = "Red\(check ? "Check" : "")Cell"
        redCell.alpha = 0
        redCell.run(.fadeAlpha(to: 1, duration: 0.2))
        addChild(redCell)
    }
    private func addMoveCircle(at pos: Pos) {
        let isEmptyCell = game.piece(at: pos) == nil
        let circle = SKShapeNode(circleOfRadius: isEmptyCell ? cellSize / 6 : cellSize * 0.45)
        circle.position = positionInBoard(at: pos)
        circle.lineWidth = isEmptyCell ? 0 : cellSize * 0.075
        circle.fillColor = .init(white: 0.4, alpha: isEmptyCell ? 0.15 : 0)
        circle.strokeColor = .init(white: 0.4, alpha: 0.2)
        circle.zPosition = 3
        circle.name = "MoveCircle"
        addChild(circle)
    }
    
    func createBoardImage() {
        boardImage?.removeFromParent()
        let width = size.height <  size.width ? size.height :  size.width
        boardImage = SKSpriteNode(texture: SKTexture(imageNamed: "Board"), size: CGSize(width: width, height: width))
        addChild(boardImage!)
    }
    
    func restart(overrideSave: Bool = true) {
        resetMoveHints()
        game.history = []
        removePieces()
        game.resetBoard(empty: noRules)
        createPieces()
        if overrideSave {
            saveGame()
        }
    }
    
    // MARK: Utils
    private func positionInBoard(at pos: Pos) -> CGPoint {
        let startX = -boardSize / 2.0
        let startY = boardSize / 2.0
        let halfSpacing = cellSize / 2
        return CGPoint(x: startX + cellSize * CGFloat(pos.x) + halfSpacing, y: startY - cellSize * CGFloat(pos.y) - halfSpacing)
    }
    private func positionInBoard(at pos: CGPoint) -> Pos {
        let startX = -boardSize / 2.0
        let startY = boardSize / 2.0
        let xd = (pos.x - startX) / cellSize
        let yd = (startY - pos.y) / cellSize
        let x = xd >= 0 ? Int(xd) : Int(xd - 1)
        let y = yd >= 0 ? Int(yd) : Int(yd - 1)
        return Pos(x: x, y: y)
    }
}

// MARK: ChessGameDelegate
extension BoardScene: ChessGameDelegate {
    func removePiece(_ piece: ChessPiece?) {
        piece?.run(.sequence([.fadeAlpha(to: 0, duration: 0.2),.removeFromParent()]))
    }
    
    func createPiece(_ piece: ChessPiece?, pos: Pos) {
        if let piece = piece {
            piece.zPosition = 1
            piece.size = pieceSize
            piece.position = positionInBoard(at: pos)
            piece.alpha = 0
            addChild(piece)
            piece.run(.sequence([.fadeAlpha(to: 1, duration: 0.2)]))
        }
    }
    
    func changePieceType(piece: ChessPiece?, at pos: Pos, to type: ChessPieceType) {
        piece?.texture = SKTexture(imageNamed: type.rawValue + "-" + piece!.pieceColor.rawValue)
    }
    func removeRedCells(includingCheck: Bool) {
        children.filter { node in node.name == "RedCell" || (includingCheck && node.name == "RedCheckCell") }.forEach { cell in cell.run(.sequence([.fadeAlpha(to: 0, duration: 0.2),.removeFromParent()])) }
    }
    
    func checkmate(kingPos: Pos, wins: ChessPieceColor?) {
        addRedCell(at: kingPos, check: true)
        run(.sequence([.wait(forDuration: 0.2),checkmateSound]))
        let alert = UIAlertController(title: wins == nil ? "Stalemate! (Draw)" : ((wins == .black) ? "Black wins! (Checkmate)" : "White wins! (Checkmate)"), message: "", preferredStyle: .alert)
        alert.addAction(.init(title: "Close", style: .cancel, handler: { _ in
            AppDelegate.review()
        }))
        if !online {
            alert.addAction(.init(title: "Start a new game", style: .default, handler: { _ in
                self.restart()
                if abs((UIApplication.shared.delegate as! AppDelegate).startTime.timeIntervalSince(Date())) > 10 {
                    self.vc.showRatingView()
                }
            }))
        } else {
//            vc.onlineGameCheckmate = true
//            vc.backButton.setImage(UIImage(systemName: "chevron.left"), for: [])
        }
        alert.view.tintColor = #colorLiteral(red: 0.4086923003, green: 0.2684660256, blue: 0.1772648394, alpha: 1)
        if !noRules {
            self.view?.window?.rootViewController?.present(alert, animated: true)
        }
    }
    func pawnReachedEnd(color: ChessPieceColor, completion: @escaping (ChessPieceType) -> ()) {
        let alert = UIAlertController(title: "Piece selection", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Queen", style: .default, handler: { _ in
            completion(.queen)
        }))
        alert.addAction(UIAlertAction(title: "Knight", style: .default, handler: { _ in
            completion(.knight)
        }))
        alert.addAction(UIAlertAction(title: "Bishop", style: .default, handler: { _ in
            completion(.bishop)
        }))
        alert.addAction(UIAlertAction(title: "Rook", style: .default, handler: { _ in
            completion(.rook)
        }))
        alert.view.tintColor = #colorLiteral(red: 0.4086923003, green: 0.2684660256, blue: 0.1772648394, alpha: 1)
        self.view?.window?.rootViewController?.present(alert, animated: true, completion: {
            if color == .black {
                UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: { () -> Void in
                    alert.view.transform = CGAffineTransform(rotationAngle: .pi)
                })
            }
        })
    }
    
    func check(kingPos: Pos) {
        addRedCell(at: kingPos, check: true)
        if !self.noSounds {
            if !self.noCheckSound {
                run(.sequence([.wait(forDuration: 0.2),checkSound]))
            } else {
                run(.sequence([.wait(forDuration: 0.2),piecePlaceSound]))
            }
        }
    }
    func uiMove(piece: ChessPiece, to position: Pos, withSound: Bool) {
        piece.run(.sequence([.move(to: positionInBoard(at: position), duration: 0.2), withSound ? .run {
            if !self.noSounds {
                self.run(self.piecePlaceSound)
            }
        }: .init()]))
    }
    func uiUndoMove(fromPos: Pos, toPos: Pos) {
        let piece = game.piece(at: toPos)
        piece?.position = positionInBoard(at: fromPos)
        piece?.run(.move(to: positionInBoard(at: toPos), duration: 0.2))
        if !noSounds {
            run(.sequence([.wait(forDuration: 0.2),/*piecePlaceSound*/]))
        }
        resetMoveHints()
    }
}

// MARK: "No rules"
extension BoardScene {
    func createPiece(pieceType: ChessPieceType, pieceColor: ChessPieceColor) {
        deselectPiece()
        
        let piece = ChessPiece(pieceColor: pieceColor, pieceType: pieceType)
        piece.zPosition = 1
        piece.size = pieceSize
        piece.position = touchPos ?? CGPoint(x: 0, y: 0)
        draggedPieceFromEditor = piece
        addChild(piece)
    }
    
    fileprivate func deleteDraggedPiece() {
        var piece: ChessPiece?
        if draggedPieceFromEditor != nil {
            piece = draggedPieceFromEditor
            draggedPieceFromEditor = nil
        } else if selectedPiece != nil {
            piece = selectedPiece
        }
        if piece?.pieceType != .king {
            if let pos = selectedPiecePos {
                perform(move: NormalMove(from: pos, to: pos, additionalMove: DestroyMove(pos: pos), doublePawnMove: false))
            } else if let piece = piece {
                // Dragged piece
                piece.run(.sequence([.fadeAlpha(to: 0, duration: 0.2),.removeFromParent()]))
            }
            game.checkChecks(ui: true)
        } else {
            bringSelectedPieceBack()
        }
    }
}

// MARK: Touches
extension BoardScene {
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
}

// MARK: Save game
extension BoardScene {
    func saveGame() {
        if !online {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try! encoder.encode(game.history)
            UserDefaults.standard.set(data, forKey: "History")
        }
    }
    
    func loadGame(history: [NormalMove]? = nil) {
        if let data = UserDefaults.standard.data(forKey: "History") {
            let jsonDecoder = JSONDecoder()
            do {
                let moves = history == nil ? (try jsonDecoder.decode(History.self, from: data)).moves : history!
                game.history = moves
                removePieces()
                for move in moves.dropLast() {
                    game.perform(move: move, addToHistory: false, uiMove: false, noRules: noRules)
                }
                if let lastMove = moves.last {
                    run(.sequence([.wait(forDuration: 0.2), .run {
                        self.game.perform(move: lastMove, addToHistory: false, uiMove: true, noRules: self.noRules)
                        self.game.checkChecks(ui: true)
                    }]))
                }
            } catch {
                print(error)
            }
        }
        createPieces()
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

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}
