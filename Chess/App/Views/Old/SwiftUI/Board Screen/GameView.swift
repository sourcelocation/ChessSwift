//
//  GameView.swift
//  Chess
//
//  Created by exerhythm on 12/9/21.
//

import SwiftUI
import SpriteKit

//struct GameView: View, GameUIDelegate {
//
//    @Environment(\.verticalSizeClass) var vss: UserInterfaceSizeClass?
//    @Environment(\.horizontalSizeClass) var hss: UserInterfaceSizeClass?
//    @Environment(\.safeAreaInsets) private var safeAreaInsets
//
//    @EnvironmentObject var settings: SettingsStore
//
//    @State var board: BoardScene?
//    @State var noRules: Bool = false
//
//    // Alets
//    @State var showingRestartAlert = false
//    @State var showingWinAlert = false
//    @State var showingTimerAlert = false
//
//    // Modal Views
//    @State var showingProView = false
//    @State var showingSettings = false
//
//    // Dismiss
//    @Binding var shown: Bool
//
//    @State var online: Bool
//
//
//    // MARK: Views
//    var body: some View {
//        GeometryReader { gp in
//            ZStack {
//                Color(#colorLiteral(red: 0.8861198425, green: 0.8416082263, blue: 0.8121766448, alpha: 1))
//                    .ignoresSafeArea()
//
//                let boardPadding:CGFloat = hss == .regular && vss == .regular ? 20 : 4
//                BoardView(board: $board, gameView: self)
//                    .padding(boardPadding)
//                    .ignoresSafeArea()
//
//                if squareControls {
//                    HStack(alignment: .center) {
//                        let leftW = barWidth(containerSize: gp.size, rightSide: false)
//                        let rightW = barWidth(containerSize: gp.size, rightSide: true)
//                        Color.green
//                            .hidden()
//                            .frame(width: leftW, height: .infinity)
//                        boardPlaceholder(size: min(gp.size.height - boardPadding * 2,gp.size.width - boardPadding * 2), containerSize: gp.size)
//                            .padding(.vertical, boardPadding)
//                        VStack(alignment: .center) {
//                            Spacer()
//                            BoardControlsView(showingSettings: $showingSettings, squareControls: squareControls, undo: undo, restart: restart, showProView: showProView, showSettingsView: showSettingsView)
//                                .padding(.bottom, 24)
//                        }
//                        .frame(width: rightW, height: .infinity)
//                    }
//                    .ignoresSafeArea()
//                } else {
//                    VStack(spacing:10) {
//                        Spacer()
//                        boardPlaceholder(size: min(gp.size.height,gp.size.width), containerSize: gp.size)
//                        BoardControlsView(showingSettings: $showingSettings, squareControls: squareControls, undo: undo, restart: restart, showProView: showProView, showSettingsView: showSettingsView)
//                        Spacer()
//                    }
//                }
//                VStack {
//                    HStack {
//                        Button {
//                            shown = false
//                        } label: {
//                            Image(systemName: "chevron.left")
//                                .font(.system(size: 24, weight: .medium))
//                        }.padding()
//
//                        Spacer()
//                    }
//                    Spacer()
//                }
//            }
//
//        }
//        .alert(isPresented: $showingRestartAlert) {
//            Alert(
//                title: Text("Start a new game?"),
//                message: Text("Are you sure you want to start a new game?"),
//                primaryButton: .default(Text("Restart"), action: {
//                    self.board!.restart()
//                    if (UIApplication.shared.delegate as! AppDelegate).startTime.timeIntervalSince(Date()) > 600 {
//                        AppDelegate.review()
//                    }
//                    //                    self.undos.wrappedValue = 0
//                    //                    self.resetClockValues()
//                    self.board?.saveGame()
//                }),
//                secondaryButton: .cancel(Text("Cancel"))
//            )
//        }
////        .sheet(isPresented: $showingProView) {
////            PremiumView(showModal: $showingProView)
////        }
//        .navigationBarHidden(true)
//    }
//
//    func boardPlaceholder(size: CGFloat, containerSize: CGSize) -> some View {
//        Color.red
//            .hidden()
//            .frame(width: size, height: size, alignment: .center)
//    }
//
//
//
//
//    // MARK: - Computed variables
//    func boardSize(size: CGFloat) -> CGFloat {
//        let padding: CGFloat = (hss == .regular && vss == .regular ? 20 : 4)
//        return squareControls ? size - padding : size - padding
//    }
//    var squareControls: Bool {
//        return UIScreen.main.bounds.width > UIScreen.main.bounds.height
//    }
//    //    func squareControlsWidth(containerSize: CGSize, rightSide: Bool) -> CGFloat {
//    //        let sideSize = (max(containerSize.width,containerSize.height) - boardSize(size: min(containerSize.height,containerSize.width))) / 2
//    //        let w = sideSize - (hss == .regular && vss == .regular ? 20 : 4) - (rightSide ? safeAreaInsets.trailing : 0)
//    //        return max(0,w)
//    //    }
//    func barWidth(containerSize: CGSize, rightSide: Bool) -> CGFloat {
////        let padding: CGFloat = (hss == .regular && vss == .regular ? 20 : 4)
//        let inset = (rightSide ? safeAreaInsets.trailing : safeAreaInsets.leading)
//        return max(0,(max(containerSize.width,containerSize.height) - boardSize(size: min(containerSize.height,containerSize.width))) / 2 - inset)
//    }
//    //    private var undos: Binding<Int> { Binding (
//    //        get: { UserDefaults.standard.integer(forKey: "undos") },
//    //        set: { UserDefaults.standard.set($0, forKey: "undos") }
//    //    )}
//
//    // MARK: - Functions
//    func undo() {
//        if !board!.game.history.isEmpty {
//            //            if undos.wrappedValue < 5 || UserDefaults.standard.bool(forKey: "pro") {
//            //                undos.wrappedValue += 1
//            board?.game.undo(noRulesEnabled: noRules)
//            board?.deselectPiece()
//            board?.saveGame()
//            //                stopTimers()
//            //            } else {
//            //                showProView()
//            //            }
//        }
//    }
//
//    func restart() {
//        showingRestartAlert.toggle()
//    }
//
//    func showProView() {
//        showingProView = true
//    }
//    func showSettingsView() {
//        showingSettings = true
//    }
//
//    // MARK: Delegate
//    func movedPiece(color: ChessPieceColor, move: NormalMove) {
//        print("movedPiece")
//    }
//
//    func bounceTimer() {
//        print("bounceTimer")
//    }
//}
//
//@available(iOS 15.0, *)
//struct GameView_Previews: PreviewProvider {
//    static var previews: some View {
//        GameView(shown: .constant(true), online: false)
//            .previewInterfaceOrientation(.landscapeRight)
//    }
//}
