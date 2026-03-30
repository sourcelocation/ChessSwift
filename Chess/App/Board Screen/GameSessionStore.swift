import SwiftUI
import UIKit
import Combine

@MainActor
final class GameSessionStore: ObservableObject {
    enum RemoteGameEvent {
        case opponentMove(NormalMove)
        case remoteStateSync(fen: String)
        case opponentResigned
        case drawOffered
    }

    protocol OnlineSessionPort {
        func sendLocalMove(_ move: NormalMove) async
    }

    struct NullOnlineSessionPort: OnlineSessionPort {
        func sendLocalMove(_ move: NormalMove) async {}
    }

    enum SessionMode: Equatable {
        case localTwoPlayers
        case replay
        case online
    }

    enum LifecycleState: Equatable {
        case idle
        case active
        case exiting
    }

    enum AnalysisState: Equatable {
        case idle
        case preparing
        case running(requestID: Int, fen: String)
        case failed(String)
    }

    enum AnalysisTerminalState: Equatable {
        case checkmate(winner: ChessPieceColor)
        case stalemate
    }

    enum Intent {
        case appear(boardSide: CGFloat)
        case boardSideChanged(CGFloat)
        case disappear
        case undo
        case redo
        case restart
        case startAnalysis
        case pieceMoved
    }

    struct Config {
        let gameType: GameType
        let loadedHistory: StoredGameHistory?
        let persistCurrentGame: Bool
        let archiveOnExit: Bool
    }

    private struct NotationGateway {
        @MainActor
        func fen(for board: BoardScene) -> String {
            board.game.getFen()
        }

        @MainActor
        func historySnapshot(for board: BoardScene, gameID: UUID) -> StoredGameHistory {
            StoredGameHistory(
                gameID: gameID,
                fromMoves: board.game.history,
                cursor: board.game.currentMoveIHistory
            )
        }
    }

    private struct PersistenceGateway {
        let repository: GameRepository

        func loadAutosaveHistory() -> StoredGameHistory {
            repository.loadAutosaveHistory()
        }

        func saveAutosaveHistory(_ history: StoredGameHistory) {
            repository.saveAutosaveHistory(history)
        }

        func upsertSavedGame(finalBoard: [[SavedChessGame.Piece?]], history: StoredGameHistory) {
            repository.upsertSavedGame(finalBoard: finalBoard, history: history)
        }
    }

    @Published private(set) var board: BoardScene

    @Published var showingRestartAlert = false
    @Published var showingWhiteRanOutOfTime = false
    @Published var showingBlackRanOutOfTime = false
    @Published var showingProView = false
    @Published var showingSettings = false
    @Published var showingEnjoymentPrompt = false

    @Published var analysisEnabled = false
    @Published var analysisPreparing = false
    @Published var analysisPreparationProgress: Double = 0
    @Published var analysisPreparationMessage: String?

    @Published var clockTurnOf: ChessPieceColor?
    @Published var whiteTimerRemaining = 10.0
    @Published var blackTimerRemaining = 10.0

    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    @Published private(set) var sessionMode: SessionMode = .localTwoPlayers
    @Published private(set) var lifecycleState: LifecycleState = .idle
    @Published private(set) var analysisState: AnalysisState = .idle
    @Published private(set) var analysisLines: [GameAnalyzer.AnalysisLine] = []
    @Published private(set) var analysisBestMove: GameAnalyzer.MoveInfo?
    @Published private(set) var analysisTerminalState: AnalysisTerminalState?
    @Published private(set) var gameSnapshot: GameSnapshot?

    let analyzer: GameAnalyzer

    private let config: Config
    private let settings: AppSettings
    private let reviewPrompt: ReviewPromptService
    private let stockfishModelDownloader: StockfishModelDownloader
    private let notation = NotationGateway()
    private let persistence: PersistenceGateway
    private let onlinePort: OnlineSessionPort
    
    var analysisAvailable: Bool {
        config.gameType == .overTheBoard
    }

    private var isReplaySession: Bool {
        config.loadedHistory != nil
    }

    private var timerWhite: Timer?
    private var timerBlack: Timer?
    private var isGameOver = false

    private var didRunExitFlow = false
    private var lastArchivedMoveCount = 0
    private var currentGameID = UUID()
    private let startTime = Date()
    private var analysisRequestVersion = 0
    private var cancellables: Set<AnyCancellable> = []

    init(
        config: Config,
        settings: AppSettings,
        repository: GameRepository,
        reviewPrompt: ReviewPromptService,
        stockfishModelDownloader: StockfishModelDownloader = .shared
    ) {
        self.config = config
        self.settings = settings
        self.reviewPrompt = reviewPrompt
        self.stockfishModelDownloader = stockfishModelDownloader
        self.persistence = PersistenceGateway(repository: repository)
        self.onlinePort = NullOnlineSessionPort()
        self.analyzer = GameAnalyzer(multiPV: 3, depth: 14)
        self.board = BoardScene(size: UIScreen.main.bounds.size)

        board.settingsProvider = BoardScene.SettingsProvider(
            isProEnabled: { settings.proEnabled },
            isSoundEnabled: { settings.soundEnabled },
            isCheckSoundEnabled: { settings.checkSoundEnabled },
            showLegalMoves: { settings.showLegalMoves },
            flipBlackPieces: { settings.flipBlackPieces }
        )

        board.movedPieceCallback = { [weak self] _, _ in
            self?.dispatch(.pieceMoved)
        }

        board.checkmateCallback = { [weak self] color in
            self?.isGameOver = true
            self?.pauseTimer()
            self?.showCheckmateAlert(for: color)
        }

        bindAnalyzer()
        updateGameSnapshot()
    }

    func onAppear(boardSide: CGFloat) {
        dispatch(.appear(boardSide: boardSide))
    }

    func onBoardSideChanged(_ boardSide: CGFloat) {
        dispatch(.boardSideChanged(boardSide))
    }

    func onDisappear() {
        dispatch(.disappear)
    }

    func undo() {
        dispatch(.undo)
    }

    func redo() {
        dispatch(.redo)
    }

    func restart() {
        dispatch(.restart)
    }

    func toggleAnalysis() {
        guard analysisAvailable else { return }
        dispatch(.startAnalysis)
    }

    func startAnalysis() {
        dispatch(.startAnalysis)
    }

    func tryAddingPieceFromPalette(type: ChessPieceType, color: ChessPieceColor, point: CGPoint) {
        board.tryAddingPieceAtDroppedPoint(type: type, color: color, point: point)
        updateGameSnapshot()
    }

    func ingestRemoteEvent(_ event: RemoteGameEvent) {
        switch event {
        case let .opponentMove(move):
            guard gameModeSupportsRemoteIngestion else { return }
            board.game.perform(move: move, addToHistory: true, uiMove: true, noRules: false)
            movedPiece()
        case .remoteStateSync:
            // Wire full remote-state hydration when online transport is enabled.
            break
        case .opponentResigned, .drawOffered:
            // UI-level handling will be added with online session UX.
            break
        }
    }

    private func dispatch(_ intent: Intent) {
        switch intent {
        case let .appear(boardSide):
            lifecycleState = .active
            sessionMode = isReplaySession ? .replay : .localTwoPlayers
            handleAppear(boardSide: boardSide)
        case let .boardSideChanged(side):
            handleBoardSideChanged(side)
        case .disappear:
            lifecycleState = .exiting
            handleDisappear()
            lifecycleState = .idle
        case .undo:
            handleUndo()
        case .redo:
            handleRedo()
        case .restart:
            handleRestart()
        case .startAnalysis:
            handleStartAnalysis()
        case .pieceMoved:
            movedPiece()
        }
    }

    private var gameModeSupportsRemoteIngestion: Bool {
        config.gameType == .online
    }

    private func handleAppear(boardSide: CGFloat) {
        configureBoardScene(boardSide: boardSide)
        if isReplaySession {
            pauseTimer()
        }

        if analysisAvailable {
            resetAnalysisState()
        } else {
            resetAnalysisState()
            analyzer.stopAnalysis()
            clearAnalysisArrows()
        }
        updateGameSnapshot()
    }

    private func handleBoardSideChanged(_ boardSide: CGFloat) {
        let updatedSize = CGSize(width: boardSide, height: boardSide)
        guard board.size != updatedSize else { return }
        board.size = updatedSize
        board.adjustSizes()
    }

    private func handleDisappear() {
        handleExitFlowIfNeeded()
        pauseTimer()
        analyzer.stopAnalysis()
    }

    private func handleUndo() {
        pauseTimer()
        isGameOver = false
        if settings.undosUsed < 4 || settings.proEnabled {
            board.undo(noRulesEnabled: config.gameType == .puzzle)
            settings.undosUsed += 1
            analyzeCurrentPosition()
            persistAutosaveIfNeeded()
            updateUndoRedoState()
            updateGameSnapshot()
        } else {
            showingProView = true
        }
    }

    private func handleRedo() {
        pauseTimer()
        isGameOver = false
        if settings.undosUsed < 4 || settings.proEnabled {
            board.redo(noRulesEnabled: config.gameType == .puzzle)
            settings.undosUsed += 1
            analyzeCurrentPosition()
            persistAutosaveIfNeeded()
            updateUndoRedoState()
            updateGameSnapshot()
        } else {
            showingProView = true
        }
    }

    private func handleRestart() {
        archiveCurrentGameIfNeeded()
        resetBoardToSelectedMode()
        isGameOver = false
        settings.undosUsed = 0
        lastArchivedMoveCount = 0

        persistAutosaveIfNeeded()
        analyzeCurrentPosition()
        updateUndoRedoState()
        updateGameSnapshot()

        presentEnjoymentPromptIfNeeded()
    }

    private func handleStartAnalysis() {
        guard analysisAvailable, !analysisEnabled, !analysisPreparing else { return }

        pauseTimer()
        analysisEnabled = true
        analysisPreparationMessage = "Preparing analyzer..."
        analysisPreparationProgress = 0
        analysisPreparing = true
        analysisState = .preparing

        Task { [weak self] in
            await self?.prepareAndStartAnalysis()
        }
    }

    func handleExitFlowIfNeeded() {
        guard !didRunExitFlow else { return }
        didRunExitFlow = true
        archiveCurrentGameIfNeeded()
    }

    func analyzeCurrentPosition() {
        guard analysisAvailable,
              analysisEnabled,
              !analysisPreparing
        else {
            return
        }

        let fen = notation.fen(for: board)
        analysisRequestVersion += 1
        analysisState = .running(requestID: analysisRequestVersion, fen: fen)
        analysisTerminalState = nil
        analyzer.analyze(fen: fen, requestID: analysisRequestVersion)
    }

    func persistAutosaveIfNeeded() {
        guard config.persistCurrentGame, config.gameType == .overTheBoard else { return }
        persistence.saveAutosaveHistory(notation.historySnapshot(for: board, gameID: currentGameID))
    }

    func resetTimer() {
        pauseTimer()
        isGameOver = false
        whiteTimerRemaining = Double(settings.chessClockMinutes) * 60
        blackTimerRemaining = Double(settings.chessClockMinutes) * 60
    }

    func resumeTimer() {
        guard settings.chessClockEnabled, !analysisEnabled, !isReplaySession else { return }
        clockTurnOf = board.game.turnOf
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

    func formatTimeToString(_ time: Double) -> String {
        let totalSeconds = max(0, Int(time.rounded(.down)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    private func configureBoardScene(boardSide: CGFloat) {
        board.size = CGSize(width: boardSide, height: boardSide)
        board.scaleMode = .aspectFill
        board.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        isGameOver = false

        switch config.gameType {
        case .overTheBoard:
            board.resetBoardAndGame()
            resetTimer()

            let history = config.loadedHistory ?? (config.persistCurrentGame ? persistence.loadAutosaveHistory() : .empty)
            currentGameID = history.gameID
            if !history.plies.isEmpty {
                board.restore(history: history.toMoves(), currentMoveIndex: history.clampedCursor)
            }
            if isReplaySession {
                pauseTimer()
            }

        case .puzzle:
            board.shouldRotatePieces = false
            var emptyBoardPieces: [[GamePieceSnapshot?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
            emptyBoardPieces[0][0] = .init(type: .king, color: .black)
            emptyBoardPieces[7][7] = .init(type: .king, color: .white)
            board.resetBoardAndGame(customBoard: emptyBoardPieces)

        case .online, .engine:
            board.resetBoardAndGame()
        }
        
        updateUndoRedoState()
    }

    private func movedPiece() {
        if config.gameType == .online, let lastMove = board.game.history.last {
            Task { [onlinePort] in
                await onlinePort.sendLocalMove(lastMove)
            }
        }
        if isGameOver {
            pauseTimer()
        } else {
            resumeTimer()
        }
        persistAutosaveIfNeeded()
        analyzeCurrentPosition()
        updateUndoRedoState()
        updateGameSnapshot()
    }

    private func prepareAndStartAnalysis() async {
        do {
            let models = try await stockfishModelDownloader.ensureModels { [weak self] progress in
                self?.analysisPreparationProgress = progress
                self?.analysisPreparationMessage = "Downloading model... \(Int(progress * 100))%"
            }

            analyzer.configureModels(
                evalFile: models.evalFile.path,
                evalFileSmall: models.evalFileSmall.path
            )
            analysisPreparing = false
            analysisPreparationMessage = nil
            analysisPreparationProgress = 1
            analysisState = .idle
            analyzeCurrentPosition()
        } catch {
            resetAnalysisState()
            analysisPreparationMessage = "Analyzer setup failed: \(error.localizedDescription)"
            analysisState = .failed(error.localizedDescription)
            analyzer.stopAnalysis()
            clearAnalysisArrows()
        }
    }

    private func resetAnalysisState() {
        analysisEnabled = false
        analysisPreparing = false
        analysisPreparationProgress = 0
        analysisPreparationMessage = nil
        analysisState = .idle
    }

    private func clearAnalysisArrows() {
        board.displayMoveArrows(moves: [])
        board.setHighlightFirstArrow(false)
        analysisLines = []
        analysisBestMove = nil
        analysisTerminalState = nil
    }

    private func archiveCurrentGameIfNeeded() {
        guard config.archiveOnExit,
              config.gameType == .overTheBoard,
              !board.game.history.isEmpty,
              board.game.history.count != lastArchivedMoveCount
        else {
            return
        }

        let currentSnapshot = board.game.snapshot()
        let finalBoard = currentSnapshot.board.map { row in
            row.map { piece -> SavedChessGame.Piece? in
                guard let piece else { return nil }
                return SavedChessGame.Piece(type: piece.type, color: piece.color)
            }
        }

        let history = notation.historySnapshot(for: board, gameID: currentGameID)
        persistence.upsertSavedGame(finalBoard: finalBoard, history: history)
        lastArchivedMoveCount = board.game.history.count
    }

    private func resetBoardToSelectedMode() {
        currentGameID = UUID()
        switch config.gameType {
        case .overTheBoard:
            board.resetBoardAndGame()
        case .puzzle:
            var emptyBoardPieces: [[GamePieceSnapshot?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
            emptyBoardPieces[0][0] = .init(type: .king, color: .black)
            emptyBoardPieces[7][7] = .init(type: .king, color: .white)
            board.shouldRotatePieces = false
            board.resetBoardAndGame(customBoard: emptyBoardPieces)
        case .online, .engine:
            board.resetBoardAndGame()
        }
    }

    private func showCheckmateAlert(for color: ChessPieceColor?) {
        guard !shouldSuppressCheckmateAlert else { return }
        UIApplication.shared.alert(
            title: color == nil
            ? "Stalemate! (Draw)".localized
            : ((color == .black) ? "Black wins! (Checkmate)".localized : "White wins! (Checkmate)".localized),
            body: ""
        )
    }

    private var shouldSuppressCheckmateAlert: Bool {
        if isReplaySession || analysisEnabled || analysisPreparing {
            return true
        }
        switch analysisState {
        case .preparing, .running:
            return true
        case .idle, .failed:
            return false
        }
    }

    func confirmEnjoymentPrompt() {
        reviewPrompt.requestIfNeeded()
        showingEnjoymentPrompt = false
    }

    func dismissEnjoymentPrompt(markReviewed: Bool) {
        if markReviewed {
            settings.hasReviewed = true
        }
        showingEnjoymentPrompt = false
    }

    private func presentEnjoymentPromptIfNeeded() {
       guard startTime.timeIntervalSinceNow < -60 else { return }
       guard !settings.hasReviewed else { return }
        showingEnjoymentPrompt = true
    }

    private func startWhiteTimer() {
        if timerWhite?.isValid != true {
            timerWhite = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.whiteTimerRemaining -= 0.1
                    if self.whiteTimerRemaining <= 0 {
                        self.isGameOver = true
                        self.showingWhiteRanOutOfTime = true
                        self.pauseTimer()
                    }
                }
            }
        }
    }

    private func startBlackTimer() {
        if timerBlack?.isValid != true {
            timerBlack = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.blackTimerRemaining -= 0.1
                    if self.blackTimerRemaining <= 0 {
                        self.isGameOver = true
                        self.showingBlackRanOutOfTime = true
                        self.pauseTimer()
                    }
                }
            }
        }
    }

    func updateUndoRedoState() {
        canUndo = !board.game.history.isEmpty && board.game.currentMoveIHistory != nil
        canRedo = !board.game.history.isEmpty && board.game.currentMoveIHistory != board.game.history.count - 1
    }

    func isRenderableAnalysisLine(_ line: GameAnalyzer.AnalysisLine) -> Bool {
        let from = line.move.from
        let to = line.move.to

        guard (0..<8).contains(from.x),
              (0..<8).contains(from.y),
              (0..<8).contains(to.x),
              (0..<8).contains(to.y)
        else {
            return false
        }

        guard let piece = gameSnapshot?.piece(at: from) else {
            return false
        }

        guard piece.color == (gameSnapshot?.turnOf ?? board.game.turnOf) else {
            return false
        }

        let legalTargets = board.game.moves(for: from).map(\.toPos)
        return legalTargets.contains(where: { $0 == to })
    }

    func pieceImageName(for move: GameAnalyzer.MoveInfo) -> String? {
        if let piece = gameSnapshot?.piece(at: move.from) {
            return "\(piece.type.rawValue)-\(piece.color.rawValue)"
        }
        if let promotion = move.promotion, let turn = gameSnapshot?.turnOf {
            return "\(promotion.rawValue)-\(turn.rawValue)"
        }
        return nil
    }

    private func bindAnalyzer() {
        analyzer.$snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                guard let self else { return }
                self.consumeAnalysisSnapshot(snapshot)
            }
            .store(in: &cancellables)
    }

    private func consumeAnalysisSnapshot(_ snapshot: GameAnalyzer.Snapshot?) {
        guard let snapshot else {
            analysisLines = []
            analysisBestMove = nil
            clearAnalysisArrows()
            return
        }

        guard case let .running(requestID, _) = analysisState, requestID == snapshot.requestID else {
            return
        }

        let filteredLines = snapshot.lines.filter { isRenderableAnalysisLine($0) }
        analysisLines = filteredLines
        if filteredLines.isEmpty, !snapshot.isAnalyzing {
            analysisTerminalState = terminalStateForCurrentPosition()
        } else {
            analysisTerminalState = nil
        }

        if let bestMove = snapshot.bestMove {
            let bestAsLine = GameAnalyzer.AnalysisLine(
                id: 0,
                index: 0,
                move: bestMove,
                score: .init(cp: nil, mate: nil),
                depth: nil
            )
            analysisBestMove = isRenderableAnalysisLine(bestAsLine) ? bestMove : nil
        } else {
            analysisBestMove = nil
        }

        let arrowMoves = filteredLines.map { NormalMove(from: $0.move.from, to: $0.move.to) }
        board.displayMoveArrows(moves: arrowMoves)
        board.setHighlightFirstArrow(analysisBestMove != nil)
        updateGameSnapshot()
    }

    private func terminalStateForCurrentPosition() -> AnalysisTerminalState? {
        let currentSnapshot = board.game.snapshot()
        let sideToMove = currentSnapshot.turnOf
        let isTerminal = board.game.logic.checkCheckmate(
            for: sideToMove,
            lastMove: board.game.slicedHistory.last,
            board: currentSnapshot.board
        )

        guard isTerminal else { return nil }
        let isInCheck = board.game.logic.checkCheck(for: sideToMove, board: currentSnapshot.board)
        if isInCheck {
            return .checkmate(winner: sideToMove.inverted)
        }
        return .stalemate
    }

    private func updateGameSnapshot() {
        gameSnapshot = board.game.snapshot()
    }
}
