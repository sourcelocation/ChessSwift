//
//  SavedGameViewController.swift
//  Chess
//
//  Created by exerhythm on 06.07.2022.
//

import UIKit
import SpriteKit

//class AnalysableGameViewController: UIViewController, GameUIDelegate {
//    enum Variant {
//        case gameViewer, editor
//    }
//    var board: BoardScene?
//    var variant: Variant = .gameViewer
//    var isLoadingVC = true
//    var stockfish = Stockfish()
//    var savedGame: SavedChessGame!
//    var moves: [Stockfish.EngineMove] = []
//
//    var isAnalyzing = false
//
//    @IBOutlet weak var tableView: UITableView!
//    @IBOutlet weak var boardView: UIView!
//    @IBOutlet var noRulesEditorPieces: [UIImageView]!
//    @IBOutlet weak var editorPiecesStack: UIStackView!
//
//    @IBAction func undoButtonPressed(_ sender: UIButton) {
//        board?.undo()
//        if isAnalyzing { analyzeBoard() }
//    }
//    @IBAction func redoButtonPressed(_ sender: UIButton) {
//        board?.redo()
//        if isAnalyzing { analyzeBoard() }
//    }
//    @IBAction func startAnalysingButtonPressed(_ sender: UIButton) {
//        isAnalyzing.toggle()
//        if isAnalyzing {
//            sender.setTitle("Stop analyzing", for: [])
//            analyzeBoard()
//        } else {
//            sender.setTitle("Start analyzing", for: [])
//            stockfish.sendStop()
//            board?.displayMoveArrows(moves: [])
//        }
//
//        // Start stockfish
//    }
//    @IBAction func restartButtonPressed(_ sender: UIButton) {
//
//    }
//
//    override func viewDidLoad() {
//        editorPiecesStack.isHidden = variant != .editor
//    }
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//
//        if isLoadingVC {
//            presentScene()
//            self.board?.resetGame()
//            self.board?.game.history = savedGame.history
//            self.board?.removePieces()
//            self.board?.createPieces()
////            self.board?.loadGameFromSave(history: savedGame.history)
////            self.board?.game.moveHistoryToBeginning()
//        }
//        isLoadingVC = false
//        setNeedsUpdateOfHomeIndicatorAutoHidden()
//    }
//    func analyzeBoard() {
//        stockfish.sendStop()
//        board?.setHighlightFirstArrow(false)
//        stockfish.getBestMoves(count: 3, fen: board!.game.getFen(), onReceiveMoves: { [weak self] moves in
//            DispatchQueue.main.async {
//                self?.board?.displayMoveArrows(moves: moves.map({ .init(from: $0.from, to: $0.to) }))
//                self?.moves = moves
//                self?.tableView.reloadData()
//            }
//        }, onReceiveBestMove: { [weak self] bestMove in
//            self?.board?.setHighlightFirstArrow(true)
//        })
//    }
//    func presentScene() {
//        board = BoardScene(size: boardView.frame.size)
//        board!.viewOnly = variant != .editor
//        board!.alignToTop = true
//        board!.vcDelegate = self
//        board!.scaleMode = .aspectFill
//        board!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
//        if let view = self.boardView as! SKView? {
//            view.presentScene(board)
//            view.ignoresSiblingOrder = true
//            view.showsFPS = false
//            view.showsNodeCount = false
//        }
//    }
//
//    func setup(as variant: Variant) {
//        self.variant = variant
//        board?.noRules = variant == .editor
//    }
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let touch = touches.first {
//            guard variant == .editor else { return }
//            for imageView in noRulesEditorPieces {
//                let location = touch.location(in: view)
//                if !(imageView.globalFrame?.contains(location) ?? false) { continue }
//                let i = imageView.tag
//
//                var pieceType: ChessPieceType!
//                var pieceColor: ChessPieceColor!
//                switch i {
//                case 0,5: pieceType = .pawn
//                case 1,6: pieceType = .knight
//                case 2,7: pieceType = .bishop
//                case 3,8: pieceType = .rook
//                case 4,9: pieceType = .queen
//                    default: pieceType = .pawn }
//                switch i {
//                case 0...4: pieceColor = .white
//                case 5...9: pieceColor = .black
//                    default: pieceColor = .white }
//
//                board?.createPiece(pieceType: pieceType, pieceColor: pieceColor)
//                break
//            }
//        }
//    }
//}
//
//extension AnalysableGameViewController: UITableViewDataSource, UITableViewDelegate {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return moves.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! AnaylzedMoveCell
//        let move = moves[indexPath.row]
//        guard let piece = board?.game.piece(at: move.from) else { return cell }
//        cell.backgroundColor = .clear
//        cell.moveTitleLabel.text = move.description()
//        cell.piceTypeLabel.text = piece.pieceType.rawValue.firstUppercased
//        cell.piceTypeImage.image = .init(named: piece.pieceType.rawValue + "-" + piece.pieceColor.rawValue)
//        return cell
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//
//        //todo perform move
//    }
//
//}
//
//extension StringProtocol {
//    var firstUppercased: String { return prefix(1).uppercased() + dropFirst() }
//    var firstCapitalized: String { return prefix(1).capitalized + dropFirst() }
//}
