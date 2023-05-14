//
//  GameView.swift
//  Chess
//
//  Created by exerhythm on 12/9/21.
//

import SwiftUI
import SpriteKit
import StoreKit
import SwiftMessages

struct GameView: View {

    @Environment(\.verticalSizeClass) var vss: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var hss: UserInterfaceSizeClass?

    @State var board: BoardScene?
    @State var noRules: Bool = false

    @State var showingRestartAlert = false
    @State var showingWinAlert = false
    @State var showingTimerAlert = false

    @State var showingProView = false
    @State var showingSettings = false

    // Dismiss
    @Binding var shown: Bool

    @State var online: Bool = false
     
    // free users
    @AppStorage("undos") var undos = 0
    
    @AppStorage("pro") var isPro = false
    
    // For asking for a review. A specified time has to pass for review popup to show
    var startTime = Date()
    
    var squareControls: Bool {
        return UIScreen.main.bounds.width > UIScreen.main.bounds.height
    }
    
    var boardPadding: CGFloat { hss == .regular && vss == .regular ? 20 : 4 }
    
    
    // MARK: Views
    var body: some View {
        GeometryReader { gp in
            ZStack {
                Color(.init(rgb: 0xF4EDE3))
                    .ignoresSafeArea()
                
                
                if let board = board {
                    SpriteView(scene: board, options: [.allowsTransparency])
                        .padding(boardPadding)
                        .ignoresSafeArea()
                }
                
                if squareControls {
                    HStack {
                        controls
                            .hidden()
                        
                        let boardSize = min(UIScreen.main.bounds.size.width - boardPadding * 2, UIScreen.main.bounds.size.height - boardPadding * 2)
                        Rectangle()
                            .frame(width: boardSize, height: boardSize)
                            .hidden()
                        controls
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack {
                        controls
                            .hidden()
                        
                        let boardSize = min(UIScreen.main.bounds.size.width - boardPadding * 2, UIScreen.main.bounds.size.height - boardPadding * 2)
                        Rectangle()
                            .frame(width: boardSize, height: boardSize)
                            .hidden()
                        controls
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                
                VStack {
                    HStack {
                        Button {
                            shown = false
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .medium))
                                .padding()
                        }

                        Spacer()
                    }
                    Spacer()
                }
            }
            .onAppear {
                createBoardScene(size: gp.size)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    // make sure we don't update multiple times for no reason
                    guard board?.size != .init(width: UIScreen.main.bounds.size.width - boardPadding * 2,
                                              height: UIScreen.main.bounds.size.height - boardPadding * 2) else { return }
                    createBoardScene(size: gp.size)
                }
            }
//            .onChange(of: gp.size) { new in
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                    createBoardScene(size: new)
//                }
//            }
        }
        .alert(isPresented: $showingRestartAlert) {
            Alert(
                title: Text("Start a new game?"),
                message: Text("Are you sure you want to start a new game?"),
                primaryButton: .default(Text("Restart"), action: {
                    self.board!.restart()
                    if startTime.timeIntervalSinceNow < -60 {
                        showRatingView()
                    }
                    self.undos = 0
                    //                    self.resetClockValues()
                    self.board?.saveGame()
                }),
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
        .sheet(isPresented: $showingProView) {
            PremiumView(showModal: $showingProView)
        }
        .navigationBarHidden(true)
    }
    
    @ViewBuilder
    var controls: some View {
        Group {
            if squareControls {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                Button {
                                    undoButtonPressed()
                                } label: {
                                    Image(systemName: "arrow.left")
                                        .padding(12)
                                }
                                Button {
                                    redoButtonPressed()
                                } label: {
                                    Image(systemName: "arrow.right")
                                        .padding(12)
                                }
                            }
                            HStack(spacing: 0) {
                                Button {
                                    restartButtonPressed()
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .padding(12)
                                }
                                Button {
                                    settingsButtonPressed()
                                } label: {
                                    Image(systemName: "gearshape")
                                        .padding(12)
                                }
                            }
                        }
                        Spacer()
                    }
                }
                .padding(.bottom)
            } else if !squareControls {
                VStack {
                    HStack(spacing: 0) {
                        Button {
                            undoButtonPressed()
                        } label: {
                            Image(systemName: "arrow.left")
                                .padding(12)
                        }
                        Button {
                            redoButtonPressed()
                        } label: {
                            Image(systemName: "arrow.right")
                                .padding(12)
                        }
                        Button {
                            restartButtonPressed()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .padding(12)
                        }
                        Button {
                            settingsButtonPressed()
                        } label: {
                            Image(systemName: "gearshape")
                                .padding(12)
                        }
                    }
                    Spacer()
                }
                .padding(.top)
            }
        }
        .font(.system(size: 28))
        .popover(isPresented: $showingSettings) {
            SettingsView()
                .frame(width: 300, height: 200)
        }
    }
    
    func undoButtonPressed() {
        if undos < 4 || isPro {
            board?.undo()
//            stopTimers()
            undos += 1
        } else {
            showingProView = true
        }
    }
    
    func redoButtonPressed() {
        if undos < 4 || isPro {
            board?.redo()
            //        stopTimers()
            undos += 1
        } else {
            showingProView = true
        }
    }
    
    func restartButtonPressed() {
        showingRestartAlert.toggle()
    }
    
    func settingsButtonPressed() {
        showingSettings = true
    }
    
    
    func createBoardScene(size: CGSize) {
        print(size)
        board = BoardScene(size: .init(width: UIScreen.main.bounds.size.width - boardPadding * 2,
                                       height: UIScreen.main.bounds.size.height - boardPadding * 2))
        board!.scaleMode = .aspectFill
        board!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
//        scene.setup()
        
        if !online {
            board!.resetGame()
            board!.loadGameFromSave()
        } else {
            //            onlineManager?.game = scene.game
            //            scene.loadGame(history: onlineManager?.serverGame?.moves)
            //            scene.allowMovesOnlyFromColor = (onlineManager?.serverGame!.whitePlayeriD == ChessAPI.login?.id) ? .white : .black
            //            scene.view?.transform =  CGAffineTransform(rotationAngle: board!.allowMovesOnlyFromColor == .white ? 0 : .pi)
        }
    }
    
    func showRatingView() {
        func review() {
            if !UserDefaults.standard.bool(forKey: "reviewed") {
                if #available(iOS 13.0, *) {
                    if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        if #available(iOS 14.0, *) {
                            SKStoreReviewController.requestReview(in: scene)
                        } else {
                            SKStoreReviewController.requestReview()
                        }
                    }
                } else {
                    SKStoreReviewController.requestReview()
                }
                UserDefaults.standard.setValue(true, forKey: "reviewed")
            }
        }
        
        if !UserDefaults.standard.bool(forKey: "reviewed") {
            let view: EnjoymentView = try! SwiftMessages.viewFromNib()
            view.yesAction = { review(); SwiftMessages.hide() }
            view.noAction = { SwiftMessages.hide(); UserDefaults.standard.set(true, forKey: "reviewed") }
            var config = SwiftMessages.defaultConfig
            config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)
            config.duration = .forever
            config.presentationStyle = .bottom
            config.dimMode = .gray(interactive: true)
            SwiftMessages.show(config: config, view: view)
        }
    }
}

@available(iOS 15.0, *)
struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(shown: .constant(true), online: false)
    }
}

