import SwiftUI
import UIKit

@MainActor
final class GameSessionStore: ObservableObject {
    struct Config {
        let gameType: GameType
        let loadedHistory: StoredGameHistory?
        let persistCurrentGame: Bool
        let archiveOnExit: Bool
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

    let analyzer: GameAnalyzer

    private let config: Config
    private let settings: AppSettings
    private let repository: GameRepository
    private let reviewPrompt: ReviewPromptService
    private let stockfishModelDownloader: StockfishModelDownloader
    
    var analysisAvailable: Bool {
        config.gameType == .overTheBoard
    }

    private var isReplaySession: Bool {
        config.loadedHistory != nil
    }

    private var timerWhite: Timer?
    private var timerBlack: Timer?

    private var didRunExitFlow = false
    private var lastArchivedMoveCount = 0
    private var currentGameID = UUID()
    private let startTime = Date()

    init(
        config: Config,
        settings: AppSettings,
        repository: GameRepository,
        reviewPrompt: ReviewPromptService,
        stockfishModelDownloader: StockfishModelDownloader = .shared
    ) {
        self.config = config
        self.settings = settings
        self.repository = repository
        self.reviewPrompt = reviewPrompt
        self.stockfishModelDownloader = stockfishModelDownloader
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
            self?.movedPiece()
        }

        board.checkmateCallback = { [weak self] color in
            self?.showCheckmateAlert(for: color)
        }
    }

    func onAppear(boardSide: CGFloat) {
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
    }

    func onBoardSideChanged(_ boardSide: CGFloat) {
        let updatedSize = CGSize(width: boardSide, height: boardSide)
        guard board.size != updatedSize else { return }
        board.size = updatedSize
        board.adjustSizes()
    }

    func onDisappear() {
        handleExitFlowIfNeeded()
        pauseTimer()
        analyzer.stopAnalysis()
    }

    func undo() {
        pauseTimer()
        if settings.undosUsed < 4 || settings.proEnabled {
            board.undo(noRulesEnabled: config.gameType == .puzzle)
            settings.undosUsed += 1
            analyzeCurrentPosition()
            persistAutosaveIfNeeded()
            updateUndoRedoState()
        } else {
            showingProView = true
        }
    }

    func redo() {
        pauseTimer()
        if settings.undosUsed < 4 || settings.proEnabled {
            board.redo(noRulesEnabled: config.gameType == .puzzle)
            settings.undosUsed += 1
            analyzeCurrentPosition()
            persistAutosaveIfNeeded()
            updateUndoRedoState()
        } else {
            showingProView = true
        }
    }

    func restart() {
        archiveCurrentGameIfNeeded()
        resetBoardToSelectedMode()
        settings.undosUsed = 0
        lastArchivedMoveCount = 0

        persistAutosaveIfNeeded()
        analyzeCurrentPosition()
        updateUndoRedoState()

        presentEnjoymentPromptIfNeeded()
    }

    func toggleAnalysis() {
        guard analysisAvailable else { return }
        startAnalysis()
    }

    func startAnalysis() {
        guard analysisAvailable, !analysisEnabled, !analysisPreparing else { return }

        pauseTimer()
        analysisEnabled = true
        analysisPreparationMessage = "Preparing analyzer..."
        analysisPreparationProgress = 0
        analysisPreparing = true

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

        analyzer.analyze(fen: board.game.getFen())
    }

    func persistAutosaveIfNeeded() {
        guard config.persistCurrentGame, config.gameType == .overTheBoard else { return }
        repository.saveAutosaveHistory(
            StoredGameHistory(
                gameID: currentGameID,
                fromMoves: board.game.history,
                cursor: board.game.currentMoveIHistory
            )
        )
    }

    func resetTimer() {
        pauseTimer()
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

        switch config.gameType {
        case .overTheBoard:
            board.resetBoardAndGame()
            resetTimer()

            let history = config.loadedHistory ?? (config.persistCurrentGame ? repository.loadAutosaveHistory() : .empty)
            currentGameID = history.gameID
            if !history.plies.isEmpty {
                board.restore(history: history.toMoves(), currentMoveIndex: history.clampedCursor)
            }
            if isReplaySession {
                pauseTimer()
            }

        case .puzzle:
            board.shouldRotatePieces = false
            var emptyBoardPieces: [[ChessPiece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
            emptyBoardPieces[0][0] = .init(pieceColor: .black, pieceType: .king)
            emptyBoardPieces[7][7] = .init(pieceColor: .white, pieceType: .king)
            board.resetBoardAndGame(customBoard: emptyBoardPieces)

        case .online, .engine:
            board.resetBoardAndGame()
        }
        
        updateUndoRedoState()
    }

    private func movedPiece() {
        resumeTimer()
        persistAutosaveIfNeeded()
        analyzeCurrentPosition()
        updateUndoRedoState()
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
            analyzeCurrentPosition()
        } catch {
            resetAnalysisState()
            analysisPreparationMessage = "Analyzer setup failed: \(error.localizedDescription)"
            analyzer.stopAnalysis()
            clearAnalysisArrows()
        }
    }

    private func resetAnalysisState() {
        analysisEnabled = false
        analysisPreparing = false
        analysisPreparationProgress = 0
        analysisPreparationMessage = nil
    }

    private func clearAnalysisArrows() {
        board.displayMoveArrows(moves: [])
        board.setHighlightFirstArrow(false)
    }

    private func archiveCurrentGameIfNeeded() {
        guard config.archiveOnExit,
              config.gameType == .overTheBoard,
              !board.game.history.isEmpty,
              board.game.history.count != lastArchivedMoveCount
        else {
            return
        }

        let finalBoard = board.game.board.map { row in
            row.map { piece -> SavedChessGame.Piece? in
                guard let piece else { return nil }
                return SavedChessGame.Piece(type: piece.pieceType, color: piece.pieceColor)
            }
        }

        let history = StoredGameHistory(
            gameID: currentGameID,
            fromMoves: board.game.history,
            cursor: board.game.currentMoveIHistory
        )
        repository.upsertSavedGame(finalBoard: finalBoard, history: history)
        lastArchivedMoveCount = board.game.history.count
    }

    private func resetBoardToSelectedMode() {
        currentGameID = UUID()
        switch config.gameType {
        case .overTheBoard:
            board.resetBoardAndGame()
        case .puzzle:
            var emptyBoardPieces: [[ChessPiece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
            emptyBoardPieces[0][0] = .init(pieceColor: .black, pieceType: .king)
            emptyBoardPieces[7][7] = .init(pieceColor: .white, pieceType: .king)
            board.shouldRotatePieces = false
            board.resetBoardAndGame(customBoard: emptyBoardPieces)
        case .online, .engine:
            board.resetBoardAndGame()
        }
    }

    private func showCheckmateAlert(for color: ChessPieceColor?) {
        guard !analysisEnabled else { return }
        UIApplication.shared.alert(
            title: color == nil
            ? "Stalemate! (Draw)".localized
            : ((color == .black) ? "Black wins! (Checkmate)".localized : "White wins! (Checkmate)".localized),
            body: ""
        )
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
}
