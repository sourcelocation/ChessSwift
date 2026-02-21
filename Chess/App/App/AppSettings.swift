import Foundation
import Combine

@MainActor
protocol SettingsStore: AnyObject {
    var proEnabled: Bool { get set }
    var chessClockEnabled: Bool { get set }
    var chessClockMinutes: Int { get set }
    var soundEnabled: Bool { get set }
    var checkSoundEnabled: Bool { get set }
    var flipBlackPieces: Bool { get set }
    var showLegalMoves: Bool { get set }
    var undosUsed: Int { get set }
    var hasReviewed: Bool { get set }
}

@MainActor
final class AppSettings: ObservableObject, SettingsStore {
    enum Key {
        static let pro = "pro"
        static let chessClock = "chessClock"
        static let chessClockTime = "chessClockTime"
        static let soundEnabled = "soundEnabled"
        static let checkSoundEnabled = "checkSoundEnabled"
        static let flipBlackPieces = "flipBlackPieces"
        static let showLegalMoves = "showLegalMoves"
        static let undos = "undos"
        static let reviewed = "reviewed"
    }

    private let defaults: UserDefaults

    @Published var proEnabled: Bool { didSet { defaults.set(proEnabled, forKey: Key.pro) } }
    @Published var chessClockEnabled: Bool { didSet { defaults.set(chessClockEnabled, forKey: Key.chessClock) } }
    @Published var chessClockMinutes: Int { didSet { defaults.set(chessClockMinutes, forKey: Key.chessClockTime) } }
    @Published var soundEnabled: Bool { didSet { defaults.set(soundEnabled, forKey: Key.soundEnabled) } }
    @Published var checkSoundEnabled: Bool { didSet { defaults.set(checkSoundEnabled, forKey: Key.checkSoundEnabled) } }
    @Published var flipBlackPieces: Bool { didSet { defaults.set(flipBlackPieces, forKey: Key.flipBlackPieces) } }
    @Published var showLegalMoves: Bool { didSet { defaults.set(showLegalMoves, forKey: Key.showLegalMoves) } }
    @Published var undosUsed: Int { didSet { defaults.set(undosUsed, forKey: Key.undos) } }
    @Published var hasReviewed: Bool { didSet { defaults.set(hasReviewed, forKey: Key.reviewed) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        proEnabled = defaults.bool(forKey: Key.pro)
        chessClockEnabled = defaults.bool(forKey: Key.chessClock)

        let storedMinutes = defaults.integer(forKey: Key.chessClockTime)
        let initialClockMinutes = storedMinutes == 0 ? 5 : storedMinutes
        chessClockMinutes = initialClockMinutes
        if storedMinutes == 0 {
            defaults.set(initialClockMinutes, forKey: Key.chessClockTime)
        }

        soundEnabled = defaults.object(forKey: Key.soundEnabled) == nil ? true : defaults.bool(forKey: Key.soundEnabled)
        checkSoundEnabled = defaults.object(forKey: Key.checkSoundEnabled) == nil ? true : defaults.bool(forKey: Key.checkSoundEnabled)
        flipBlackPieces = defaults.object(forKey: Key.flipBlackPieces) == nil ? true : defaults.bool(forKey: Key.flipBlackPieces)
        showLegalMoves = defaults.object(forKey: Key.showLegalMoves) == nil ? true : defaults.bool(forKey: Key.showLegalMoves)
        undosUsed = defaults.integer(forKey: Key.undos)
        hasReviewed = defaults.bool(forKey: Key.reviewed)
    }
}
