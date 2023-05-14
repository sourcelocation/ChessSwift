////
////  SavedGamesViewController.swift
////  Chess
////
////  Created by exerhythm on 05.07.2022.
////
//
//import UIKit
//
//class SavedGamesViewController: UICollectionViewController {
//    var games: [SavedChessGame] = []//[.init(finalBoard: ChessGame.initialBoard.map { $0.map { $0 != nil ? .init(type: $0!.pieceType, color: $0!.pieceColor) : nil}}, history: []), .init(finalBoard: ChessGame.initialBoard.map { $0.map { $0 != nil ? .init(type: $0!.pieceType, color: $0!.pieceColor) : nil}}, history: []), .init(finalBoard: ChessGame.initialBoard.map { $0.map { $0 != nil ? .init(type: $0!.pieceType, color: $0!.pieceColor) : nil}}, history: [])]
//
//    var insetForCells:CGFloat {
//        let screenSize: CGRect = UIScreen.main.bounds
//        if screenSize.width > 375 {
//            return 24
//        }
//        return 12
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        let layout = UICollectionViewFlowLayout()
//
//        layout.minimumInteritemSpacing = insetForCells
//        layout.minimumLineSpacing = insetForCells
//
//        collectionView.collectionViewLayout = layout
//
//        if let data = UserDefaults.standard.data(forKey: "SavedGames") {
//            games = try! JSONDecoder().decode([SavedChessGame].self, from: data)
//        }
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        navigationController?.setNavigationBarHidden(false, animated: true)
//    }
//
////    override func numberOfSections(in collectionView: UICollectionView) -> Int {
////        return 1
////    }
////
////
////    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
////        return 0
////    }
////
////    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
////        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
////
////        // Configure the cell
////
////        return cell
////    }
////
////    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
////        return false
////    }
////
////    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
////        return false
////    }
////
////    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
////
////    }
//}
//
//
//// MARK: Collection View
//extension SavedGamesViewController: UICollectionViewDelegateFlowLayout {
//    override func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return 1
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return games.count
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let game = games[indexPath.row]
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! SavedGameViewCell
//        let board = BoardScene(size: .init(width: cell.frame.size.width, height: cell.frame.size.height))
//        board.game.board = game.finalBoard.map { $0.map { $0 != nil ? .init($0!.color, $0!.type) : nil }}
//        board.setUpSizes()
//        board.createPieces()
//        board.viewOnly = true
//        board.scaleMode = .aspectFill
//        board.anchorPoint = CGPoint(x: 0.5, y: 0.5)
//        if let view = cell.board {
//            view.presentScene(board)
//            view.ignoresSiblingOrder = true
//            view.showsFPS = false
//            view.showsNodeCount = false
//        }
//        return cell
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let game = games[indexPath.row]
//        performSegue(withIdentifier: "ViewGame", sender: game)
//    }
//
////    override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
////        return true
////    }
////
////    override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//
////    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return UIEdgeInsets(top: insetForCells, left: insetForCells, bottom: insetForCells, right: insetForCells)
//    }
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//        return 1
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let edge: CGFloat = insetForCells * 1.25
//        let spacing: CGFloat = insetForCells
//        let noOfColumn = 2
//        let collectionviewWidth = collectionView.frame.width
//        let bothEdge =  CGFloat(edge + edge) // left + right
//        let excludingEdge = collectionviewWidth - bothEdge
//        let cellWidthExcludingSpaces = excludingEdge - (CGFloat((noOfColumn-1)) * spacing)
//        let finalCellWidth = cellWidthExcludingSpaces / CGFloat(noOfColumn)
//        let height = finalCellWidth + 20
//
//        return CGSize(width: finalCellWidth, height: height)
//    }
//
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        guard let dest = segue.destination as? AnalysableGameViewController else { return }
//        dest.setup(as: .gameViewer)
//        dest.savedGame = sender as! SavedChessGame
//    }
//    // MARK: - Context menu
//
////    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
////        if !isEditing {
////            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
////                return self.makeContextMenu(for: indexPath.row)
////            })
////        } else {
////            return nil
////        }
////    }
////    func makeContextMenu(for index:Int) -> UIMenu {
////        var actions = [UIAction]()
////        let contextMenuItems = [
////            ContextMenuItem(title: LocalizedString("Rename"), image: UIImage(systemName: "pencil")!, index: 0)
////        ]
////
////        for item in contextMenuItems {
////            let action = UIAction(title: item.title, image: item.image, identifier: nil, discoverabilityTitle: nil) { _ in
////                self.didSelectContextMenu(menuIndex: item.index, cellIndex: index)
////            }
////            actions.append(action)
////        }
////        let menu = UIMenu(title: "", children: actions)
////        return menu
////    }
////    func didSelectContextMenu(menuIndex: Int, cellIndex: Int) {
////        let editAlert = UIAlertController(title: LocalizedString("Edit word"), message: "", preferredStyle: .alert)
////        editAlert.addTextField { (textField) in
////            textField.text = LocalizedString(Collections.shared().collections[cellIndex].collectionName)
////            textField.autocorrectionType = .yes
////            textField.autocapitalizationType = .words
////        }
////        editAlert.addAction(UIAlertAction(title: LocalizedString("Cancel"), style: .cancel))
////        editAlert.addAction(UIAlertAction(title: LocalizedString("Edit"), style: .default,handler: { _ in
////            Collections.shared().collections[cellIndex].collectionName = editAlert.textFields![0].text!
////            self.collectionView.reloadItems(at: [IndexPath(row: cellIndex, section: 0)])
////        }))
////        self.present(editAlert, animated: true)
////    }
//}
//
////struct ContextMenuItem {
////  var title = ""
////  var image = UIImage()
////  var index = 0
////}
