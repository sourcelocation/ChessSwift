import Foundation

protocol GameRepository {
    func loadAutosaveHistory() -> StoredGameHistory
    func saveAutosaveHistory(_ history: StoredGameHistory)
    func clearAutosaveHistory()

    func loadSavedGames() -> [SavedChessGame]
    func saveSavedGames(_ games: [SavedChessGame])
    func upsertSavedGame(finalBoard: [[SavedChessGame.Piece?]], history: StoredGameHistory)
}

final class DefaultGameRepository: GameRepository {
    private enum Key {
        static let autosaveHistory = "game.autosave.history"
    }

    private let defaults: UserDefaults
    private let fileURL: URL

    init(defaults: UserDefaults = .standard, fileManager: FileManager = .default) {
        self.defaults = defaults

        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directory = appSupport.appendingPathComponent("Chess", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        fileURL = directory.appendingPathComponent("saved-games.json")
    }

    func loadAutosaveHistory() -> StoredGameHistory {
        if let data = defaults.data(forKey: Key.autosaveHistory),
           let history = try? JSONDecoder().decode(StoredGameHistory.self, from: data) {
            return history
        }

        if defaults.data(forKey: Key.autosaveHistory) != nil {
            defaults.removeObject(forKey: Key.autosaveHistory)
        }

        return .empty
    }

    func saveAutosaveHistory(_ history: StoredGameHistory) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(history) {
            defaults.set(data, forKey: Key.autosaveHistory)
        }
    }

    func clearAutosaveHistory() {
        defaults.removeObject(forKey: Key.autosaveHistory)
    }

    func loadSavedGames() -> [SavedChessGame] {
        if let data = try? Data(contentsOf: fileURL),
           let games = try? JSONDecoder().decode([SavedChessGame].self, from: data) {
            return games
        }

        return []
    }

    func saveSavedGames(_ games: [SavedChessGame]) {
        if let data = try? JSONEncoder().encode(games) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    func upsertSavedGame(finalBoard: [[SavedChessGame.Piece?]], history: StoredGameHistory) {
        guard !history.plies.isEmpty else { return }
        var games = loadSavedGames()
        let game = SavedChessGame(id: history.gameID, createdAt: Date(), finalBoard: finalBoard, history: history)
        games.removeAll { $0.id == history.gameID }
        games.insert(game, at: 0)
        saveSavedGames(games)
    }
}
