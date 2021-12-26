//
//  BoardView.swift
//  Chess
//
//  Created by exerhythm on 12/12/21.
//

import SwiftUI
import SpriteKit

//struct BoardView: View {
//    @Binding var board: BoardScene?
//    var gameView: GameView
//    
//    var body: some View {
//        GeometryReader { gp in
//            VStack {
//                if let boardScene = board {
//                    SpriteView(scene: boardScene, options: [.allowsTransparency])
//                }
//            }
//            .onAppear {
//                board = createBoardScene(size: gp.size)
//            }
//            .onChange(of: gp.size, perform: { size in
//                board = createBoardScene(size: size)
//            })
//        }
//    }
//    
//    func createBoardScene(size: CGSize) -> BoardScene {
//        let scene = BoardScene(size: size)
//        scene.scaleMode = .aspectFit
//        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
//        scene.vcDelegate = gameView
////        scene.setup()
//        
//        if !gameView.online {
//            scene.loadGame()
//        } else {
//            //            onlineManager?.game = scene.game
//            //            scene.loadGame(history: onlineManager?.serverGame?.moves)
//            //            scene.allowMovesOnlyFromColor = (onlineManager?.serverGame!.whitePlayeriD == ChessAPI.login?.id) ? .white : .black
//            //            scene.view?.transform =  CGAffineTransform(rotationAngle: board!.allowMovesOnlyFromColor == .white ? 0 : .pi)
//        }
//        return scene
//    }
//}
//
////struct BoardView_Previews: PreviewProvider {
////    static var previews: some View {
////        BoardView()
////    }
////}
