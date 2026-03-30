import Foundation
import ChessKitEngine

@MainActor
final class GameAnalyzer: ObservableObject {
    enum RunState: Equatable {
        case idle
        case starting
        case analyzing
        case stopping
        case failed(String)
    }

    struct Snapshot: Equatable {
        let requestID: Int
        let fen: String
        let lines: [AnalysisLine]
        let bestMove: MoveInfo?
        let isAnalyzing: Bool
        let runState: RunState
    }

    struct AnalysisRequest: Equatable {
        let id: Int
        let fen: String
    }

    struct AnalysisScore: Equatable {
        let cp: Double?
        let mate: Int?

        var text: String {
            if let mate {
                return "M\(mate)"
            }
            if let cp {
                return String(format: "%+.2f", cp / 100.0)
            }
            return "-"
        }
    }

    struct ModelOptions {
        let evalFile: String
        let evalFileSmall: String
    }

    struct AnalysisLine: Identifiable, Equatable {
        let id: Int
        let index: Int
        let move: MoveInfo
        let score: AnalysisScore
        let depth: Int?

        var title: String {
            "#\(index) \(move.description)"
        }
    }

    struct MoveInfo: Equatable {
        let from: Pos
        let to: Pos
        let promotion: ChessPieceType?

        var description: String {
            let fromText = AnalyzerNotation.coordinateString(for: from)
            let toText = AnalyzerNotation.coordinateString(for: to)
            if let promotion {
                return "\(fromText) -> \(toText)=\(promotion.rawValue.prefix(1).uppercased())"
            }
            return "\(fromText) -> \(toText)"
        }
    }

    @Published private(set) var lines: [AnalysisLine] = []
    @Published private(set) var bestMove: MoveInfo?
    @Published private(set) var isAnalyzing = false
    @Published private(set) var runState: RunState = .idle
    @Published private(set) var snapshot: Snapshot?

    private let engine = Engine(type: .stockfish)
    private let multiPV: Int
    private let depth: Int

    private var streamTask: Task<Void, Never>?
    private var analyzeTask: Task<Void, Never>?
    private var started = false
    private var isShuttingDown = false
    private var lineByIndex: [Int: AnalysisLine] = [:]
    private var modelOptions: ModelOptions?
    private var activeRequest: AnalysisRequest?

    init(multiPV: Int = 3, depth: Int = 14) {
        self.multiPV = max(1, multiPV)
        self.depth = max(1, depth)
    }

    // MARK: Public API

    func configureModels(evalFile: String, evalFileSmall: String) {
        modelOptions = .init(evalFile: evalFile, evalFileSmall: evalFileSmall)
        guard started, !isShuttingDown else { return }
        Task { [weak self] in
            await self?.applyModelOptions()
        }
    }

    func analyze(fen: String?, requestID: Int) {
        guard let fen, !fen.isEmpty, !isShuttingDown else { return }
        let request = AnalysisRequest(id: requestID, fen: fen)
        begin(request: request)
        startAnalyzeTask(for: request)
    }

    func stopAnalysis() {
        analyzeTask?.cancel()
        runState = .stopping
        analyzeTask = Task { [weak self] in
            guard let self else { return }
            await self.engine.send(command: .stop)
        }
        activeRequest = nil
        resetInFlightResult()
    }

    func shutdown() async {
        guard !isShuttingDown else { return }
        isShuttingDown = true

        analyzeTask?.cancel()
        analyzeTask = nil
        await engine.send(command: .stop)
        streamTask?.cancel()
        streamTask = nil
        await engine.stop()
        started = false
        activeRequest = nil
        resetInFlightResult()
        isShuttingDown = false
    }

    // MARK: Analyze Pipeline

    private func begin(request: AnalysisRequest) {
        activeRequest = request
        resetInFlightResult()
    }

    private func startAnalyzeTask(for request: AnalysisRequest) {
        analyzeTask?.cancel()
        analyzeTask = Task { [weak self] in
            guard let self else { return }
            guard self.isRequestCurrent(request) else { return }
            self.runState = .starting
            guard await self.prepareEngine(for: request) else { return }
            guard await self.applyPosition(for: request) else { return }
            self.setAnalyzingIfCurrent(request)
            guard self.isRequestCurrent(request) else { return }
            await self.engine.send(command: .go(depth: self.depth))
        }
    }

    private func prepareEngine(for request: AnalysisRequest) async -> Bool {
        await ensureStarted()
        return started && isRequestCurrent(request)
    }

    private func applyPosition(for request: AnalysisRequest) async -> Bool {
        guard isRequestCurrent(request) else { return false }
        await engine.send(command: .stop)
        guard isRequestCurrent(request) else { return false }
        await engine.send(command: .setoption(id: "MultiPV", value: "\(multiPV)"))
        guard isRequestCurrent(request) else { return false }
        await engine.send(command: .position(.fen(request.fen)))
        return isRequestCurrent(request)
    }

    private func setAnalyzingIfCurrent(_ request: AnalysisRequest) {
        guard isRequestCurrent(request) else { return }
        isAnalyzing = true
        runState = .analyzing
        publishSnapshotIfPossible()
    }

    // MARK: Engine Lifecycle

    private func ensureStarted() async {
        guard !isShuttingDown, !Task.isCancelled else { return }

        if !started {
            await engine.start(coreCount: ProcessInfo.processInfo.activeProcessorCount, multipv: multiPV)

            var attempts = 0
            while await !engine.isRunning, attempts < 80, !Task.isCancelled, !isShuttingDown {
                attempts += 1
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }

        let running = await engine.isRunning
        guard running, !isShuttingDown else {
            started = false
            return
        }
        guard !Task.isCancelled else { return }

        started = true
        await ensureResponseStreamAttached()

        guard !Task.isCancelled, !isShuttingDown else { return }
        await engine.send(command: .setoption(id: "UCI_AnalyseMode", value: "true"))
        await applyModelOptions()
    }

    private func isRequestCurrent(_ request: AnalysisRequest) -> Bool {
        !isShuttingDown && !Task.isCancelled && activeRequest == request
    }

    private func ensureResponseStreamAttached() async {
        guard streamTask == nil, let stream = await engine.responseStream else { return }
        streamTask = Task { [weak self] in
            for await response in stream {
                await self?.consume(response: response)
            }
        }
    }

    private func applyModelOptions() async {
        guard let modelOptions else { return }
        await engine.send(command: .setoption(id: "EvalFile", value: modelOptions.evalFile))
        await engine.send(command: .setoption(id: "EvalFileSmall", value: modelOptions.evalFileSmall))
    }

    // MARK: Engine Responses

    private func consume(response: EngineResponse) async {
        guard !isShuttingDown else { return }
        switch response {
        case let .info(info):
            consumeInfo(info)
        case let .bestmove(move, _):
            consumeBestMove(move)
        default:
            break
        }
    }

    private func consumeInfo(_ info: EngineResponse.Info) {
        guard isAnalyzing,
              let request = activeRequest,
              let pv = info.pv,
              let firstMove = pv.first,
              let move = AnalyzerNotation.moveInfo(from: firstMove),
              AnalyzerNotation.isMoveConsistentWithPosition(move, fen: request.fen)
        else {
            return
        }

        let index = max(1, info.multipv ?? 1)
        let line = AnalysisLine(
            id: index,
            index: index,
            move: move,
            score: AnalyzerNotation.score(from: info.score, fen: request.fen),
            depth: info.depth
        )

        lineByIndex[index] = line
        lines = lineByIndex.values.sorted(by: { $0.index < $1.index })
        publishSnapshotIfPossible()
    }

    private func consumeBestMove(_ uciMove: String) {
        if let request = activeRequest,
           let parsedMove = AnalyzerNotation.moveInfo(from: uciMove),
           AnalyzerNotation.isMoveConsistentWithPosition(parsedMove, fen: request.fen) {
            bestMove = parsedMove
        } else {
            bestMove = nil
        }
        isAnalyzing = false
        runState = .idle
        publishSnapshotIfPossible()
    }

    // MARK: Snapshot + State

    private func resetInFlightResult() {
        isAnalyzing = false
        bestMove = nil
        lines = []
        lineByIndex = [:]
        if case .failed = runState {
            // Keep explicit failure until the next analyze() call overrides it.
        } else {
            runState = .idle
        }
        publishSnapshotIfPossible()
    }

    private func publishSnapshotIfPossible() {
        guard let activeRequest else {
            snapshot = nil
            return
        }
        snapshot = Snapshot(
            requestID: activeRequest.id,
            fen: activeRequest.fen,
            lines: lines,
            bestMove: bestMove,
            isAnalyzing: isAnalyzing,
            runState: runState
        )
    }
}

private enum AnalyzerNotation {
    nonisolated static func score(from score: EngineResponse.Info.Score?, fen: String) -> GameAnalyzer.AnalysisScore {
        guard let score else { return GameAnalyzer.AnalysisScore(cp: nil, mate: nil) }
        guard let sideToMove = sideToMove(from: fen) else {
            return GameAnalyzer.AnalysisScore(cp: score.cp, mate: score.mate)
        }

        let multiplier = sideToMove == .white ? 1.0 : -1.0
        let normalizedCP = score.cp.map { $0 * multiplier }
        let normalizedMate = score.mate.map { Int(Double($0) * multiplier) }
        return GameAnalyzer.AnalysisScore(cp: normalizedCP, mate: normalizedMate)
    }

    nonisolated static func moveInfo(from uciMove: String) -> GameAnalyzer.MoveInfo? {
        guard uciMove.count >= 4 else { return nil }
        let fromPart = String(uciMove.prefix(2))
        let toPart = String(uciMove.dropFirst(2).prefix(2))

        guard let from = position(from: fromPart),
              let to = position(from: toPart)
        else {
            return nil
        }

        var promotion: ChessPieceType?
        if uciMove.count > 4 {
            let promoChar = String(uciMove.dropFirst(4).prefix(1)).lowercased()
            promotion = pieceType(fromPromotionChar: promoChar)
        }

        return GameAnalyzer.MoveInfo(from: from, to: to, promotion: promotion)
    }

    nonisolated static func coordinateString(for pos: Pos) -> String {
        ["a", "b", "c", "d", "e", "f", "g", "h"][pos.x] + String(8 - pos.y)
    }

    nonisolated static func isMoveConsistentWithPosition(_ move: GameAnalyzer.MoveInfo, fen: String) -> Bool {
        guard let sideToMove = sideToMove(from: fen),
              let pieceColor = pieceColor(at: move.from, fen: fen)
        else {
            return false
        }
        return sideToMove == pieceColor
    }

    private nonisolated static func pieceType(fromPromotionChar value: String) -> ChessPieceType? {
        switch value {
        case "q": return .queen
        case "r": return .rook
        case "b": return .bishop
        case "n": return .knight
        default: return nil
        }
    }

    private nonisolated static func position(from coordinate: String) -> Pos? {
        guard coordinate.count == 2 else { return nil }
        let chars = Array(coordinate)
        let file = chars[0]
        let rank = chars[1]

        let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
        guard let fileIndex = files.firstIndex(of: String(file)),
              let rankValue = Int(String(rank)),
              rankValue >= 1,
              rankValue <= 8
        else {
            return nil
        }

        return Pos(x: fileIndex, y: 8 - rankValue)
    }

    private nonisolated static func sideToMove(from fen: String) -> ChessPieceColor? {
        let parts = fen.split(separator: " ")
        guard parts.count >= 2 else { return nil }
        return parts[1] == "w" ? .white : (parts[1] == "b" ? .black : nil)
    }

    private nonisolated static func pieceColor(at pos: Pos, fen: String) -> ChessPieceColor? {
        let parts = fen.split(separator: " ")
        guard let boardPart = parts.first else { return nil }
        let ranks = boardPart.split(separator: "/")
        guard ranks.count == 8, (0..<8).contains(pos.y) else { return nil }

        let rank = ranks[pos.y]
        var file = 0
        for char in rank {
            if let skip = char.wholeNumberValue {
                file += skip
                continue
            }
            guard file < 8 else { return nil }
            if file == pos.x {
                return char.isUppercase ? .white : .black
            }
            file += 1
        }
        return nil
    }
}
