//
//  Stockfish.swift
//  TestApp
//
//  Created by exerhythm on 05.07.2022.
//

import Foundation

class Stockfish {
    var loaded = false
    var refreshTimer: Timer?
    var depth = 12
    var maxcores: Int = {
        let processInfo = ProcessInfo()
        return processInfo.activeProcessorCount
    }()
    
    init() {
        setStockfishNNUEPath(Bundle.main.path(forResource: "nn-9e3c6298299a.nnue", ofType: nil))
        engine_initialize(0, Int32(maxcores), 20, 2) // engineid (stockf), cores, skill, nnueMode (2 is nnue only)
        
    }
    func getBestMoves(count: Int, fen: String?, sortBestMoves: ChessPieceColor? = nil, onReceiveMoves: @escaping ([EngineMove]) -> (), onReceiveBestMove: @escaping (EngineMove) -> ()) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.setEngineParam(key: "MultiPV", value: "\(count)")
            self.sendToEngine(cmd: self.uciPosition(fen: fen))
            self.sendToEngine(cmd: self.searchMoveCmd())
            
            DispatchQueue.main.async {
                self.refreshTimer?.invalidate()
                self.refreshTimer = .scheduledTimer(withTimeInterval: 0.15, repeats: true, block: { [weak self] _ in
                    while let s = self?.getSearchMessage() {
                        let response = self?.processEngineOutput(s)
                        if let moves = response as? EngineResponseMoves {
                            onReceiveMoves(moves.moves)
                        } else if let bestMove = response as? EngineResponseBestMove {
                            onReceiveBestMove(bestMove.move)
                        }
                    }
                })
            }
        }
    }
    
    
    private func processEngineOutput(_ origStr: String) -> EngineResponse? {
        var moves: [EngineMove] = []
        for line in origStr.split(separator: "\n") {
            let response = processEngineLineOutput(String(line))
            if let move = response as? EngineResponseMove {
                moves.append(move.move)
            } else if let move = response as? EngineResponseBestMove {
                return move
            }
        }
        if moves.count > 0 {
            return EngineResponseMoves(moves: moves)
        } else {
            return nil
        }
    }
    
    private func processEngineLineOutput(_ str: String) -> EngineResponse? {
        if str.starts(with: "info "), str.contains("pv") {
            let arr = str.split(separator: " ")
            if arr.count > 1 {
                let move = moveFromCoordiateString(String(arr[arr.firstIndex(of: "pv")! + 1]))
                if let multipvStrIndex = arr.firstIndex(of: "multipv"), let moveIndex = Int(arr[multipvStrIndex + 1]) {
                    return EngineResponseMove(move: .init(from: move.from, to: move.to, promotion: move.promotion), index: moveIndex)
                }
            }
        } else if str.starts(with: "bestmove ") {
            let arr = str.split(separator: " ")
            if arr.count > 1 {
                let coorStr = String(arr[arr.firstIndex(of: "bestmove")! + 1])
                if coorStr == "(none)" { return nil }
                let move = moveFromCoordiateString(coorStr)
                return EngineResponseBestMove(move: .init(from: move.from, to: move.to, promotion: move.promotion))
            }
        }
        return nil
    }
    
    // MARK: - Utils
    private func sendToEngine(cmd: String) {
        engine_cmd(0, cmd)
    }
    private func uciPosition(fen: String?) -> String {
        var cmd = "position "
        if fen == nil {
            cmd += "startpos"
        } else {
            cmd += "fen \(fen!)"
        }
        return cmd
    }
    
    private func searchMoveCmd() -> String {
        "go depth \(depth)"
    }
    private func setEngineParam(key: String, value: String) {
        sendToEngine(cmd: "setoption name \(key) value \(value)")
    }
    private func getSearchMessage() -> String? {
        if let ptr = engine_getSearchMessage(0) {
            let s = String(cString: ptr)
            if !s.isEmpty {
                return s
            }
        }
        return nil
    }
    func sendStop() {
        sendToEngine(cmd: "stop")
    }
    
    static let columnNames = ["a","b","c","d","e","f","g","h"]
    static private func posToCoordinateString(_ pos: Pos) -> String {
        return columnNames[pos.x] + String(8 - pos.y)
    }
    
    private func intPosToPos(_ i: Int) -> Pos {
        return .init(x: i % 8, y: i / 8)
    }
    
    private func coordinateStringToPos(_ str: String) -> Pos {
        if str.count >= 2 {
            let colChr = str[0], rowChr = str[1]
            if colChr >= "a" && colChr <= "h" && rowChr >= "1" && rowChr <= "8",
               let row = Int(rowChr) {
                let idx = Stockfish.columnNames.firstIndex(of: colChr)
                let col = Stockfish.columnNames.distance(from: Stockfish.columnNames.startIndex, to: idx!)
                return Pos(x: col, y: 8 - row)
            }
        }
        fatalError("Invalid string")
    }
    
    private func moveFromCoordiateString(_ moveString: String) -> EngineMove {
        let from = coordinateStringToPos(moveString.substring(toIndex: 2))
        let dest = coordinateStringToPos(moveString.substring(fromIndex: 2))
//        var promotion: Int = nil
//        if moveString.length > 4 {
//            var ch = moveString[4]
//            if ch == "=" && moveString.length > 5 {
//                ch = moveString[5]
//            }
//            let t = PieceTypeStd.charactor2PieceType(str: ch).rawValue
//            if t > 1 && t <= 6 {
//                promotion = t
//            }
//        }
        
        return EngineMove(from: from, to: dest, promotion: nil)
    }
    
    
    
    class EngineResponse { }
    struct EngineMove {
        var from: Pos!
        var to: Pos!
        var promotion: Int!
        
        func description() -> String {
            return "\(Stockfish.posToCoordinateString(from)) → \(Stockfish.posToCoordinateString(to))"
        }
    }
    class EngineResponseMove: EngineResponse {
        var index: Int
        var move: EngineMove
        
        init(move: EngineMove, index: Int) {
            self.move = move
            self.index = index
        }
    }
    class EngineResponseBestMove: EngineResponse {
        var move: EngineMove
        
        init(move: EngineMove) {
            self.move = move
        }
    }
    class EngineResponseMoves: EngineResponse {
        var moves: [EngineMove]
        
        init(moves: [EngineMove]) {
            self.moves = moves
        }
    }
}
