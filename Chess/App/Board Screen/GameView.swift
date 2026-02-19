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
    
    // Clock stuff
    @State var clockTurnOf: ChessPieceColor? = nil
    @State var whiteTimerRemaining = 10.0
    @State var blackTimerRemaining = 10.0
    @State var timerWhite: Timer?
    @State var timerBlack: Timer?

    @State var showingRestartAlert = false
    @State var showingWinAlert = false
    @State var showingTimerAlert = false
    @State var showingWhiteRanOutOfTime = false
    @State var showingBlackRanOutOfTime = false


    @State var showingProView = false
    @State var showingSettings = false

    // Dismiss
    @Binding var shown: Bool

    @State var gameType: GameType = .overTheBoard
    
    @State var draggedPiecePosition: CGPoint = .zero
     
    // free users
    @AppStorage("undos") var undos = 0
    
    @AppStorage("chessClock") var chessClockEnabled = false
    @AppStorage("chessClockTime") var chessClockTime = 5 // in minutes
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
                        VStack {
                            if gp.size.height > 500 {
                                controls
                                    .hidden()
                            }
                            if chessClockEnabled && gameType == .overTheBoard {
                                clock
                            } else if gameType == .puzzle {
                                Spacer()
                                customBoardPieces
                                    .padding()
                                Spacer()
                            } else {
                                Spacer()
                            }
                            controls
                        }
                        .padding(.vertical)
                    }
                    .ignoresSafeArea()
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    .ignoresSafeArea()
                    .padding(.vertical)
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
//                board = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    // make sure we don't update multiple times for no reason
                    guard board?.size != .init(width: UIScreen.main.bounds.size.width - boardPadding * 2,
                                              height: UIScreen.main.bounds.size.height - boardPadding * 2) else { return }
                    board?.size = .init(width: UIScreen.main.bounds.size.width - boardPadding * 2,
                                        height: UIScreen.main.bounds.size.height - boardPadding * 2)
                    board?.adjustSizes()
//                    createBoardScene(size: gp.size)
                }
            }
//            .onChange(of: gp.size) { new in
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                    createBoardScene(size: new)
//                }
//            }
        }
        .sheet(isPresented: $showingProView) {
            PremiumView(showModal: $showingProView)
        }
        .navigationBarHidden(true)
    }
    
    @ViewBuilder
    var controls: some View {
        VStack {
            if squareControls {
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
                                showingSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                                    .padding(12)
                            }
                        }
                    }
                    Spacer()
                }
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
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .alert(isPresented: $showingRestartAlert) {
            Alert(
                title: Text("Start a new game?"),
                message: Text("Are you sure you want to start a new game?"),
                primaryButton: .default(Text("Restart"), action: {
                    self.board!.resetBoardAndGame()
                    if startTime.timeIntervalSinceNow < -60 {
                        showRatingView()
                    }
                    self.undos = 0
                    //                    self.resetClockValues()
                    if gameType == .overTheBoard {
                        self.board?.saveGame()
                    }
                    
                    resetTimer()
                }),
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }
    
    @ViewBuilder
    var clock: some View {
        let activeColor = Color(.init(rgb: 0xAA724A))
//        let activeColor = Color(.init(rgb: 0x7E5536))
        //        let nonactiveColor = Color(.init(rgb: 0x5E3E25))
        let nonactiveColor = Color(.init(rgb: 0x7E5536))
        VStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(clockTurnOf == nil ? nonactiveColor : (clockTurnOf == .black ?  activeColor : nonactiveColor))
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                Text("\(formatTimeToString(blackTimerRemaining))")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                    .rotationEffect(.radians(.pi / 2))
            }
            .alert(isPresented: $showingBlackRanOutOfTime) {
                Alert(
                    title: Text("White wins! (Timeout)"),
                    message: Text(""),
                    dismissButton: .default(Text("OK"), action: {
                        chessClockEnabled = false
                    })
                )
            }
            
            ZStack {
                Rectangle()
                    .fill(clockTurnOf == nil ? nonactiveColor : (clockTurnOf == .white ?  activeColor : nonactiveColor))
                    .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                Text("\(formatTimeToString(whiteTimerRemaining))")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                    .rotationEffect(.radians(.pi / 2))
            }
            .alert(isPresented: $showingWhiteRanOutOfTime) {
                Alert(
                    title: Text("Black wins! (Timeout)"),
                    message: Text(""),
                    dismissButton: .default(Text("OK"), action: {
                        chessClockEnabled = false
                    })
                )
            }
            
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .onChange(of: chessClockTime) { newValue in
            resetTimer()
        }
    }
    
    @ViewBuilder
    var customBoardPieces: some View {
        HStack {
            ForEach([ChessPieceColor.white, .black], id: \.self) { color in
                VStack {
                    ForEach([ChessPieceType.pawn, .knight, .bishop, .rook, .queen], id: \.self) { type in
                        DraggableChessPiece(tryAddingPieceAtDroppedPoint: { point in
                            board?.tryAddingPieceAtDroppedPoint(type: type, color: color, point: point)
                        }, chessPieceType: type, chessPieceColor: color)
                    }
                }
            }
        }
    }
    
    struct DraggableChessPiece: View {
        var tryAddingPieceAtDroppedPoint: (CGPoint) -> ()
        
        @State var position: CGPoint = .zero
        @State var initialPosition: CGPoint = .zero
        @State var chessPieceType: ChessPieceType
        @State var chessPieceColor: ChessPieceColor

        var body: some View {
            GeometryReader { p in
                Image("\(chessPieceType.rawValue)-\(chessPieceColor.rawValue)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .position(position)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                position = gesture.location
                            }
                            .onEnded { _ in
                                tryAddingPieceAtDroppedPoint(
                                    CGPoint(x: p.frame(in: .global).origin.x + position.x - UIScreen.main.bounds.width / 2,
                                                                   y: -(p.frame(in: .global).origin.y + position.y - UIScreen.main.bounds.height / 2)) )
                                position = initialPosition
                            }
                    )
                    .onAppear {
                        initialPosition = .init(x: p.size.width / 2, y: p.size.height / 2)
                        position = initialPosition
                    }
            }

        }
    }
                                
    
    func undoButtonPressed() {
        pauseTimer()
        if undos < 4 || isPro {
            board?.undo(noRulesEnabled: gameType == .puzzle)
//            stopTimers()
            undos += 1
        } else {
            showingProView = true
        }
    }
    
    func redoButtonPressed() {
        pauseTimer()
        if undos < 4 || isPro {
            board?.redo(noRulesEnabled: gameType == .puzzle)
            //        stopTimers()
            undos += 1
        } else {
            showingProView = true
        }
    }
    
    func restartButtonPressed() {
        showingRestartAlert = true
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
        
        board!.movedPieceCallback = movedPiece
        board!.checkmateCallback = checkmate
        
        switch gameType {
        case .overTheBoard:
            board!.resetBoardAndGame()
            board!.loadGameFromSave()
            
            resetTimer()
        case .puzzle:
            board!.shouldRotatePieces = false
            
            var emptyBoardPieces: [[ChessPiece?]] = Array(repeating:Array(repeating: nil, count: 8),count:8)
            emptyBoardPieces[0][0] = .init(pieceColor: .black, pieceType: .king)
            emptyBoardPieces[7][7] = .init(pieceColor: .white, pieceType: .king)

            board!.resetBoardAndGame(customBoard: emptyBoardPieces)
            //            onlineManager?.game = scene.game
            //            scene.loadGame(history: onlineManager?.serverGame?.moves)
            //            scene.allowMovesOnlyFromColor = (onlineManager?.serverGame!.whitePlayeriD == ChessAPI.login?.id) ? .white : .black
            //            scene.view?.transform =  CGAffineTransform(rotationAngle: board!.allowMovesOnlyFromColor == .white ? 0 : .pi)
        case .online:
            break
        case .engine:
            break
        }
    }
    
    func movedPiece(color: ChessPieceColor, move: Move) {
        resumeTimer()
        if gameType == .overTheBoard {
            board?.saveGame()
        }
    }
    func checkmate(color: ChessPieceColor?) {
        UIApplication.shared.alert(title: color == nil ? "Stalemate! (Draw)".localized : ((color == .black) ? "Black wins! (Checkmate)".localized : "White wins! (Checkmate)".localized), body: "")
    }
    
    func resetTimer() {
        pauseTimer()
        whiteTimerRemaining = chessClockTime * 60
        blackTimerRemaining = chessClockTime * 60
    }
    
//    func changedTimerSettings() {
//        resetTimer()
//    }
    
    func showRatingView() {
        func review() {
            if !UserDefaults.standard.bool(forKey: "reviewed") {
                if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: scene)
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
    
    
    // MARK: - Clock -
    func resumeTimer() {
        clockTurnOf = board!.game.turnOf
        if clockTurnOf == .white {
            timerBlack?.invalidate()
            startWhiteTimer()
        } else {
            timerWhite?.invalidate()
            startBlackTimer()
        }
    }
    func pauseTimer() {
        clockTurnOf = nil
        timerWhite?.invalidate()
        timerBlack?.invalidate()
    }
    fileprivate func startWhiteTimer() {
        if !(timerWhite?.isValid ?? false) {
            timerWhite = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { t in
                whiteTimerRemaining -= 0.1
                
                if whiteTimerRemaining <= 0 {
                    showingWhiteRanOutOfTime = true
                    pauseTimer()
                }
            })
        }
    }
    fileprivate func startBlackTimer() {
        if !(timerBlack?.isValid ?? false) {
            timerBlack = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { t in
                blackTimerRemaining -= 0.1
                
                if blackTimerRemaining <= 0 {
                    showingBlackRanOutOfTime = true
                    pauseTimer()
                }
            })
        }
    }
    
    func formatTimeToString(_ time: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.second, .minute]
        formatter.zeroFormattingBehavior = [ .pad ]
        return formatter.string(from: time) ?? "5:00"
    }
}

@available(iOS 15.0, *)
struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(shown: .constant(true), gameType: .overTheBoard)
    }
}

