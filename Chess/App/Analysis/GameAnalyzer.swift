import Foundation
import ChessKitEngine

@MainActor
final class GameAnalyzer: ObservableObject {
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
            let fromText = GameAnalyzer.coordinateString(for: from)
            let toText = GameAnalyzer.coordinateString(for: to)
            if let promotion {
                return "\(fromText) -> \(toText)=\(promotion.rawValue.prefix(1).uppercased())"
            }
            return "\(fromText) -> \(toText)"
        }
    }

    @Published private(set) var lines: [AnalysisLine] = []
    @Published private(set) var bestMove: MoveInfo?
    @Published private(set) var isAnalyzing = false

    private let engine = Engine(type: .stockfish)
    private let multiPV: Int
    private let depth: Int

    private var streamTask: Task<Void, Never>?
    private var analyzeTask: Task<Void, Never>?
    private var started = false
    private var isShuttingDown = false
    private var lineByIndex: [Int: AnalysisLine] = [:]
    private var modelOptions: ModelOptions?

    init(multiPV: Int = 3, depth: Int = 14) {
        self.multiPV = max(1, multiPV)
        self.depth = max(1, depth)
    }

    func configureModels(evalFile: String, evalFileSmall: String) {
        modelOptions = .init(evalFile: evalFile, evalFileSmall: evalFileSmall)
        guard started, !isShuttingDown else { return }
        Task { [weak self] in
            await self?.applyModelOptions()
        }
    }

    func analyze(fen: String?) {
        guard let fen, !fen.isEmpty, !isShuttingDown else { return }
        resetInFlightResult()
        analyzeTask?.cancel()

        analyzeTask = Task { [weak self] in
            guard let self else { return }
            guard !self.isShuttingDown else { return }
            await self.ensureStarted()
            guard self.started, !self.isShuttingDown else { return }
            await self.engine.send(command: .stop)
            await self.engine.send(command: .setoption(id: "MultiPV", value: "\(self.multiPV)"))
            await self.engine.send(command: .position(.fen(fen)))
            await MainActor.run {
                self.isAnalyzing = true
            }
            guard !self.isShuttingDown else { return }
            await self.engine.send(command: .go(depth: self.depth))
        }
    }

    func stopAnalysis() {
        analyzeTask?.cancel()
        analyzeTask = Task { [weak self] in
            guard let self else { return }
            await self.engine.send(command: .stop)
        }
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
        resetInFlightResult()
        isShuttingDown = false
    }

    private func ensureStarted() async {
        guard !started, !isShuttingDown else { return }

        await engine.start(coreCount: ProcessInfo.processInfo.activeProcessorCount, multipv: multiPV)

        var attempts = 0
        while await !engine.isRunning, attempts < 80 {
            attempts += 1
            try? await Task.sleep(nanoseconds: 50_000_000)
        }

        guard await engine.isRunning, !isShuttingDown else {
            started = false
            return
        }
        started = true

        if streamTask == nil, let stream = await engine.responseStream {
            streamTask = Task { [weak self] in
                for await response in stream {
                    await self?.consume(response: response)
                }
            }
        }

        await engine.send(command: .setoption(id: "UCI_AnalyseMode", value: "true"))
        await applyModelOptions()
    }

    private func applyModelOptions() async {
        guard let modelOptions else { return }
        await engine.send(command: .setoption(id: "EvalFile", value: modelOptions.evalFile))
        await engine.send(command: .setoption(id: "EvalFileSmall", value: modelOptions.evalFileSmall))
    }

    private func consume(response: EngineResponse) async {
        guard !isShuttingDown else { return }
        switch response {
        case let .info(info):
            guard isAnalyzing,
                  let pv = info.pv,
                  let firstMove = pv.first,
                  let move = Self.moveInfo(from: firstMove)
            else { return }

            let index = max(1, info.multipv ?? 1)
            let line = AnalysisLine(
                id: index,
                index: index,
                move: move,
                score: Self.score(from: info.score),
                depth: info.depth
            )

            lineByIndex[index] = line
            lines = lineByIndex.values.sorted(by: { $0.index < $1.index })

        case let .bestmove(move, _):
            bestMove = Self.moveInfo(from: move)
            isAnalyzing = false

        default:
            break
        }
    }

    private func resetInFlightResult() {
        isAnalyzing = false
        bestMove = nil
        lines = []
        lineByIndex = [:]
    }

    nonisolated private static func score(from score: EngineResponse.Info.Score?) -> AnalysisScore {
        guard let score else { return AnalysisScore(cp: nil, mate: nil) }
        return AnalysisScore(cp: score.cp, mate: score.mate)
    }

    nonisolated private static func moveInfo(from uciMove: String) -> MoveInfo? {
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

        return MoveInfo(from: from, to: to, promotion: promotion)
    }

    nonisolated private static func pieceType(fromPromotionChar value: String) -> ChessPieceType? {
        switch value {
        case "q": return .queen
        case "r": return .rook
        case "b": return .bishop
        case "n": return .knight
        default: return nil
        }
    }

    nonisolated private static func position(from coordinate: String) -> Pos? {
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

    nonisolated private static func coordinateString(for pos: Pos) -> String {
        ["a", "b", "c", "d", "e", "f", "g", "h"][pos.x] + String(8 - pos.y)
    }
}
