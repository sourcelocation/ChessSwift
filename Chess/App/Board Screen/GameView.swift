import SwiftUI
import SpriteKit

struct GameView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var shown: Bool

    let gameType: GameType
    let loadedHistory: StoredGameHistory?
    let persistCurrentGame: Bool
    let archiveOnExit: Bool
    let screenTitle: String

    @ObservedObject private var settings: AppSettings
    @StateObject private var session: GameSessionStore
    @State private var displayedLines: [GameAnalyzer.AnalysisLine] = []
    @State private var displayedBestMove: GameAnalyzer.MoveInfo?
    @State private var measuredBoardSide: CGFloat = 0

    private enum LayoutMode {
        case regularPortrait
        case regularLandscape
        case replayPortrait
        case replayLandscape

        var isLandscape: Bool {
            self == .regularLandscape || self == .replayLandscape
        }

        var isReplay: Bool {
            self == .replayPortrait || self == .replayLandscape
        }
    }

    private struct LayoutConstants {
        let horizontalPadding: CGFloat = 12
        let verticalPadding: CGFloat = 8
        let compactSpacing: CGFloat = 10
        let regularSpacing: CGFloat = 12
        let controlsPortraitHeight: CGFloat = 64
        let controlsRailWidth: CGFloat = 56
        let regularLandscapeSidePanelWidth: CGFloat = 132
        let replayAnalyzerPortraitHeight: CGFloat = 220
        let replayAnalyzerLandscapeWidth: CGFloat = 320
    }

    private struct LayoutMetrics {
        let mode: LayoutMode
        let showsClock: Bool
    }

    private var isReplayMode: Bool {
        loadedHistory != nil
    }

    private var showsAnalysisPanel: Bool {
        session.analysisAvailable && (session.analysisEnabled || session.analysisPreparing || session.analysisPreparationMessage != nil)
    }

    init(
        shown: Binding<Bool>,
        gameType: GameType = .overTheBoard,
        loadedHistory: StoredGameHistory? = nil,
        persistCurrentGame: Bool = true,
        archiveOnExit: Bool = true,
        screenTitle: String = "Game"
    ) {
        self._shown = shown
        self.gameType = gameType
        self.loadedHistory = loadedHistory
        self.persistCurrentGame = persistCurrentGame
        self.archiveOnExit = archiveOnExit
        self.screenTitle = screenTitle

        let env = AppEnvironment.shared
        _settings = ObservedObject(wrappedValue: env.settings)
        _session = StateObject(wrappedValue: GameSessionStore(
            config: .init(
                gameType: gameType,
                loadedHistory: loadedHistory,
                persistCurrentGame: persistCurrentGame,
                archiveOnExit: archiveOnExit
            ),
            settings: env.settings,
            repository: env.gameRepository,
            reviewPrompt: env.reviewPrompt
        ))
    }

    var body: some View {
        GeometryReader { geometry in
            let metrics = layoutMetrics(for: geometry)
            ZStack {
                Color(.init(rgb: 0xF4EDE3)).ignoresSafeArea()
                mainContent(metrics: metrics)
                enjoymentPromptOverlay

                VStack {
                    HStack {
                        Button(action: leaveGame) {
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
                let fallbackBoardSide = max(1, min(geometry.size.width, geometry.size.height))
                session.onAppear(boardSide: max(measuredBoardSide, fallbackBoardSide))
            }
            .onDisappear {
                session.onDisappear()
            }
        }
        .onChange(of: measuredBoardSide) { side in
            session.onBoardSideChanged(side)
        }
        .sheet(isPresented: $session.showingProView) {
            PremiumView(showModal: $session.showingProView)
        }
        .sheet(isPresented: $session.showingSettings) {
            SettingsView()
        }
        .onReceive(session.analyzer.$lines) { lines in
            let moves = lines.map { NormalMove(from: $0.move.from, to: $0.move.to) }
            session.board.displayMoveArrows(moves: moves)
            if !lines.isEmpty {
                displayedLines = lines
            } else if !session.analysisEnabled {
                displayedLines = []
            }
        }
        .onReceive(session.analyzer.$bestMove) { bestMove in
            session.board.setHighlightFirstArrow(bestMove != nil)
            displayedBestMove = bestMove
        }
        .onChange(of: session.analysisEnabled) { enabled in
            if !enabled {
                displayedLines = []
                displayedBestMove = nil
            }
        }
        .onChange(of: settings.chessClockMinutes) { _ in
            session.resetTimer()
        }
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private var enjoymentPromptOverlay: some View {
        if session.showingEnjoymentPrompt {
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        session.dismissEnjoymentPrompt(markReviewed: false)
                    }

                VStack(spacing: 12) {
                    Text("Hey there! 🤙")
                        .font(.headline)
                        .foregroundStyle(Color(.init(rgb: 0x2C2016)))

                    Text("Are you enjoying this app?")
                        .font(.subheadline)
                        .foregroundStyle(Color(.init(rgb: 0x4B3729)))

                    HStack(spacing: 10) {
                        Button(action: {
                            session.dismissEnjoymentPrompt(markReviewed: true)
                        }) {
                            Text("Not really")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(.init(rgb: 0xCDB6A2)))

                        Button(action: {
                            session.confirmEnjoymentPrompt()
                        }) {
                            Text("Yes")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(.init(rgb: 0x8A6348)))
                    }
                }
                .padding(16)
                .frame(maxWidth: 420)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.init(rgb: 0xF4EDE3)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(.init(rgb: 0x6D4A34)).opacity(0.25), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .zIndex(10)
            .animation(.easeInOut(duration: 0.2), value: session.showingEnjoymentPrompt)
        }
    }

    private func layoutMetrics(for geometry: GeometryProxy) -> LayoutMetrics {
        let mode = layoutMode(for: geometry)
        return LayoutMetrics(
            mode: mode,
            showsClock: showsClock(mode: mode)
        )
    }

    @ViewBuilder
    private func mainContent(metrics: LayoutMetrics) -> some View {
        switch metrics.mode {
        case .regularPortrait:
            regularPortraitLayout(metrics: metrics)
        case .regularLandscape:
            regularLandscapeLayout(metrics: metrics)
        case .replayPortrait:
            replayPortraitLayout(metrics: metrics)
        case .replayLandscape:
            replayLandscapeLayout(metrics: metrics)
        }
    }

    @ViewBuilder
    private func regularPortraitLayout(metrics: LayoutMetrics) -> some View {
        let constants = LayoutConstants()
        VStack(spacing: constants.compactSpacing) {
            Spacer()
            if metrics.showsClock {
                portraitTopClockCard
            }

            boardSurface()
                .layoutPriority(1)

            if metrics.showsClock {
                portraitBottomClockCard
            }

            controls(isLandscape: false)
                .frame(height: constants.controlsPortraitHeight)

            Spacer()

            if !metrics.showsClock && showsAnalysisPanel {
                analysisPanel(isLandscape: false)
                    .padding(.horizontal, constants.horizontalPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, constants.horizontalPadding)
        .padding(.top, constants.verticalPadding)
        .padding(.bottom, constants.verticalPadding)
    }

    @ViewBuilder
    private func regularLandscapeLayout(metrics: LayoutMetrics) -> some View {
        let constants = LayoutConstants()
        let rightPanelWidth = showsAnalysisPanel
            ? constants.replayAnalyzerLandscapeWidth
            : constants.regularLandscapeSidePanelWidth
        let sidePanelWidth = max(constants.regularLandscapeSidePanelWidth, rightPanelWidth)
        HStack(spacing: constants.regularSpacing) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                controls(isLandscape: true)
                    .frame(width: constants.controlsRailWidth)
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .frame(width: sidePanelWidth, alignment: .trailing)

            boardSurface()
                .layoutPriority(1)

            Group {
                if showsAnalysisPanel {
                    analysisPanel(isLandscape: true)
                        .frame(width: constants.replayAnalyzerLandscapeWidth, alignment: .top)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else if metrics.showsClock {
                    VStack {
                        landscapeClockPanel
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .frame(width: constants.regularLandscapeSidePanelWidth)
                } else {
                    VStack {
                        landscapeClockPlaceholder
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .frame(width: constants.regularLandscapeSidePanelWidth)
                }
            }
            .frame(width: sidePanelWidth, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, constants.horizontalPadding)
        .padding(.top, constants.verticalPadding)
        .padding(.bottom, constants.verticalPadding)
        .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
    }

    @ViewBuilder
    private func replayPortraitLayout(metrics: LayoutMetrics) -> some View {
        let constants = LayoutConstants()
        VStack(spacing: constants.compactSpacing) {
            boardSurface()
                .layoutPriority(1)

            replayAnalysisPanel(isLandscape: false)
                .frame(minHeight: 180, idealHeight: constants.replayAnalyzerPortraitHeight, maxHeight: 260)
                .padding(.horizontal, constants.horizontalPadding)

            controls(isLandscape: false)
                .frame(height: constants.controlsPortraitHeight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, constants.horizontalPadding)
        .padding(.top, constants.verticalPadding)
        .padding(.bottom, constants.verticalPadding)
    }

    @ViewBuilder
    private func replayLandscapeLayout(metrics: LayoutMetrics) -> some View {
        let constants = LayoutConstants()
        HStack(spacing: constants.regularSpacing) {
            controls(isLandscape: true)
                .frame(width: constants.controlsRailWidth)

            boardSurface()
                .layoutPriority(1)

            replayAnalysisPanel(isLandscape: true)
                .frame(width: constants.replayAnalyzerLandscapeWidth, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, constants.horizontalPadding)
        .padding(.top, 0)
        .padding(.bottom, 0)
        .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
    }

    private func layoutMode(for geometry: GeometryProxy) -> LayoutMode {
        let isLandscape = geometry.size.width > geometry.size.height
        if isReplayMode {
            return isLandscape ? .replayLandscape : .replayPortrait
        }
        return isLandscape ? .regularLandscape : .regularPortrait
    }

    private func showsClock(mode: LayoutMode) -> Bool {
        guard !mode.isReplay else { return false }
        return settings.chessClockEnabled && gameType == .overTheBoard && !session.analysisEnabled
    }

    private func boardSurface() -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                SpriteView(scene: session.board, options: [.allowsTransparency])
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            updateMeasuredBoardSide(min(proxy.size.width, proxy.size.height))
                        }
                        .onChange(of: proxy.size) { newSize in
                            updateMeasuredBoardSide(min(newSize.width, newSize.height))
                        }
                }
            }
    }

    private func updateMeasuredBoardSide(_ rawSide: CGFloat) {
        let normalized = max(0, rawSide.rounded(.down))
        guard abs(normalized - measuredBoardSide) >= 1 else { return }
        measuredBoardSide = normalized
    }

    @ViewBuilder
    private func replayAnalysisPanel(isLandscape: Bool) -> some View {
        if showsAnalysisPanel {
            analysisPanel(isLandscape: isLandscape)
        } else {
            analysisStartPlaceholder(isLandscape: isLandscape)
        }
    }

    @ViewBuilder
    private func analysisStartPlaceholder(isLandscape: Bool) -> some View {
        VStack(spacing: 14) {
            Text("Replay Analysis")
                .font(.headline)
                .foregroundColor(.primary)

            Button(action: session.startAnalysis) {
                Text(session.analysisPreparing ? "Preparing..." : "Start analysing")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color(.init(rgb: 0x8A6348)), in: Capsule())
            }
            .disabled(session.analysisPreparing)
        }
        .padding(20)
        .frame(maxWidth: isLandscape ? 340 : .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func controls(isLandscape: Bool) -> some View {
        Group {
            if isLandscape {
                VStack(spacing: 0) {
                    controlButton("arrow.left", action: session.undo, enabled: session.canUndo)
                    controlButton("arrow.right", action: session.redo, enabled: session.canRedo)
                    controlButton("flag.checkered", action: { session.showingRestartAlert = true })
                    controlButton("gearshape", action: { session.showingSettings = true })
                }
            } else {
                HStack(spacing: 0) {
                    controlButton("arrow.left", action: session.undo, enabled: session.canUndo)
                    controlButton("arrow.right", action: session.redo, enabled: session.canRedo)
                    controlButton("flag.checkered", action: { session.showingRestartAlert = true })
                    controlButton("gearshape", action: { session.showingSettings = true })
                }
                .frame(maxWidth: .infinity)
            }
        }
        .font(.system(size: 28))
        .alert(isPresented: $session.showingRestartAlert) {
            Alert(
                title: Text("Start a new game?"),
                message: Text("Are you sure you want to start a new game?"),
                primaryButton: .default(Text("Restart"), action: session.restart),
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }

    private func controlButton(_ systemName: String, action: @escaping () -> Void, enabled: Bool = true) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .padding(12)
        }
        .disabled(!enabled)
    }

    @ViewBuilder
    private func analysisPanel(isLandscape: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Analyzer")
                    .font(.headline)
                Spacer()
                if session.analyzer.isAnalyzing {
                    ProgressView().scaleEffect(0.8)
                }
            }

            evaluationBar

            if displayedLines.isEmpty && !session.analysisPreparing {
                Text("No lines yet")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(displayedLines) { line in
                            analysisLineRow(line)
                        }
                    }
                }
            }

            if session.analysisPreparing {
                ProgressView(value: session.analysisPreparationProgress)
            }
            if let message = session.analysisPreparationMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: isLandscape ? 340 : .infinity, alignment: .top)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var portraitTopClockCard: some View {
        portraitClockCard(
            time: session.formatTimeToString(session.blackTimerRemaining),
            isActive: session.clockTurnOf == .black,
            background: Color(.init(rgb: 0x8A6348)),
            activeBackground: Color(.init(rgb: 0xAA724A)),
            foreground: .white
        )
        .alert(isPresented: $session.showingBlackRanOutOfTime) {
            Alert(
                title: Text("White wins! (Timeout)"),
                message: Text(""),
                dismissButton: .default(Text("OK"), action: {
                    settings.chessClockEnabled = false
                })
            )
        }
    }

    private var portraitBottomClockCard: some View {
        portraitClockCard(
            time: session.formatTimeToString(session.whiteTimerRemaining),
            isActive: session.clockTurnOf == .white,
            background: Color(.init(rgb: 0xDCC6B3)),
            activeBackground: Color(.init(rgb: 0xE9D7C8)),
            foreground: Color.black.opacity(0.78)
        )
        .alert(isPresented: $session.showingWhiteRanOutOfTime) {
            Alert(
                title: Text("Black wins! (Timeout)"),
                message: Text(""),
                dismissButton: .default(Text("OK"), action: {
                    settings.chessClockEnabled = false
                })
            )
        }
    }

    private func portraitClockCard(
        time: String,
        isActive: Bool,
        background: Color,
        activeBackground: Color,
        foreground: Color
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isActive ? activeBackground : background)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(.init(rgb: 0x6D4A34)), lineWidth: 2)
            Text(time)
                .font(.title2.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .foregroundStyle(foreground)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, minHeight: 54, maxHeight: 54)
    }

    private var landscapeClockPanel: some View {
        clock
    }

    private var landscapeClockPlaceholder: some View {
        clock
            .hidden()
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private func analysisLineRow(_ line: GameAnalyzer.AnalysisLine) -> some View {
        HStack(spacing: 10) {
            pieceIcon(for: line)

            VStack(alignment: .leading, spacing: 2) {
                Text("#\(line.index) \(line.move.description)")
                    .font(.subheadline)
                    .lineLimit(1)
                Text("Depth \(line.depth ?? 0)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 8)

            Text(line.score.text)
                .font(.system(.subheadline, design: .monospaced))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isBest(line: line) ? Color.brown.opacity(0.16) : Color.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var evaluationBar: some View {
        let score = displayedLines.first?.score
        let fraction = evaluationFraction(from: score)

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Eval")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(score?.text ?? "-")
                    .font(.system(.caption, design: .monospaced))
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.black.opacity(0.15))
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.white.opacity(0.9))
                        .frame(width: proxy.size.width * fraction)
                }
            }
            .frame(height: 12)
        }
    }

    private func evaluationFraction(from score: GameAnalyzer.AnalysisScore?) -> CGFloat {
        guard let score else { return 0.5 }
        if let mate = score.mate {
            return mate > 0 ? 1 : 0
        }
        guard let cp = score.cp else { return 0.5 }
        let clamped = max(-1200.0, min(1200.0, cp))
        return CGFloat((clamped + 1200.0) / 2400.0)
    }

    @ViewBuilder
    private func pieceIcon(for line: GameAnalyzer.AnalysisLine) -> some View {
        if let imageName = pieceImageName(for: line.move) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)
        } else {
            Image(systemName: "circle.fill")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 22, height: 22)
        }
    }

    private func pieceImageName(for move: GameAnalyzer.MoveInfo) -> String? {
        guard (0..<8).contains(move.from.y), (0..<8).contains(move.from.x) else { return nil }
        if let piece = session.board.game.board[move.from.y][move.from.x] {
            return "\(piece.pieceType.rawValue)-\(piece.pieceColor.rawValue)"
        }
        if let promotion = move.promotion {
            return "\(promotion.rawValue)-\(session.board.game.turnOf.rawValue)"
        }
        return nil
    }

    @ViewBuilder
    private var clock: some View {
        let lightBg = Color(.init(rgb: 0xDCC6B3))
        let darkBg = Color(.init(rgb: 0x8A6348))
        let lightActiveBg = Color(.init(rgb: 0xE9D7C8))
        let darkActiveBg = Color(.init(rgb: 0xAA724A))
        let borderColor = Color(.init(rgb: 0x6D4A34))

        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(session.clockTurnOf == .black ? darkActiveBg : darkBg)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(borderColor, lineWidth: 2)
                Text(session.formatTimeToString(session.blackTimerRemaining))
                    .font(.largeTitle.monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(.white)
                    .rotationEffect(.radians(.pi / 2))
                    .padding(.horizontal, 8)
            }
            .frame(width: 96, height: 168)
            .alert(isPresented: $session.showingBlackRanOutOfTime) {
                Alert(
                    title: Text("White wins! (Timeout)"),
                    message: Text(""),
                    dismissButton: .default(Text("OK"), action: {
                        settings.chessClockEnabled = false
                    })
                )
            }

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(session.clockTurnOf == .white ? lightActiveBg : lightBg)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(borderColor, lineWidth: 2)
                Text(session.formatTimeToString(session.whiteTimerRemaining))
                    .font(.largeTitle.monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(.black.opacity(0.78))
                    .rotationEffect(.radians(.pi / 2))
                    .padding(.horizontal, 8)
            }
            .frame(width: 96, height: 168)
            .alert(isPresented: $session.showingWhiteRanOutOfTime) {
                Alert(
                    title: Text("Black wins! (Timeout)"),
                    message: Text(""),
                    dismissButton: .default(Text("OK"), action: {
                        settings.chessClockEnabled = false
                    })
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var customBoardPieces: some View {
        HStack {
            ForEach([ChessPieceColor.white, .black], id: \.self) { color in
                VStack {
                    ForEach([ChessPieceType.pawn, .knight, .bishop, .rook, .queen], id: \.self) { type in
                        DraggableChessPiece { point in
                            session.board.tryAddingPieceAtDroppedPoint(type: type, color: color, point: point)
                        } chessPieceType: {
                            type
                        } chessPieceColor: {
                            color
                        }
                    }
                }
            }
        }
    }

    private func isBest(line: GameAnalyzer.AnalysisLine) -> Bool {
        guard let bestMove = displayedBestMove else { return false }
        return line.move == bestMove
    }

    private func leaveGame() {
        session.handleExitFlowIfNeeded()
        shown = false
        dismiss()
    }
}

private struct DraggableChessPiece: View {
    let tryAddingPieceAtDroppedPoint: (CGPoint) -> Void
    let chessPieceType: () -> ChessPieceType
    let chessPieceColor: () -> ChessPieceColor

    @State private var position: CGPoint = .zero
    @State private var initialPosition: CGPoint = .zero

    var body: some View {
        GeometryReader { proxy in
            Image("\(chessPieceType().rawValue)-\(chessPieceColor().rawValue)")
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
                                CGPoint(
                                    x: proxy.frame(in: .global).origin.x + position.x - UIScreen.main.bounds.width / 2,
                                    y: -(proxy.frame(in: .global).origin.y + position.y - UIScreen.main.bounds.height / 2)
                                )
                            )
                            position = initialPosition
                        }
                )
                .onAppear {
                    initialPosition = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    position = initialPosition
                }
        }
    }
}

#Preview("iPhone") {
    GameView(shown: .constant(true), gameType: .overTheBoard)
}

#Preview("iPad") {
    GameView(shown: .constant(true), gameType: .overTheBoard)
}
