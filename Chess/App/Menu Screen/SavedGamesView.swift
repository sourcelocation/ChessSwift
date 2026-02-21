import SwiftUI

struct SavedGamesView: View {
    @State private var games: [SavedChessGame] = []
    @State private var showingPremium = false
    @State private var showingProAlert = false

    private let repository: GameRepository = AppEnvironment.shared.gameRepository
    @ObservedObject private var settings = AppEnvironment.shared.settings

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            if games.isEmpty {
                emptyState
                    .padding(.top, 40)
                    .padding(.horizontal, 24)
            } else {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                        card(for: game, at: index)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .background(Color(.init(rgb: 0xF4EDE3)).ignoresSafeArea())
        .navigationTitle("Saved games")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPremium) {
            PremiumView(showModal: $showingPremium)
        }
        .alert("Pro Required", isPresented: $showingProAlert) {
            Button("Not Now", role: .cancel) {}
            Button("Get Pro") {
                showingPremium = true
            }
        } message: {
            Text("Accessing entire history requires Pro.")
        }
        .onAppear {
            games = repository.loadSavedGames()
        }
    }

    @ViewBuilder
    private func card(for game: SavedChessGame, at index: Int) -> some View {
        let locked = !settings.proEnabled && index > 0

        if locked {
            Button(action: { showingProAlert = true }) {
                SavedGameCard(game: game, locked: true)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(role: .destructive) {
                    delete(game)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        } else {
            NavigationLink {
                GameView(
                    shown: .constant(true),
                    gameType: .overTheBoard,
                    loadedHistory: game.history,
                    persistCurrentGame: false,
                    archiveOnExit: false,
                    screenTitle: "Saved Game"
                )
            } label: {
                SavedGameCard(game: game, locked: false)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(role: .destructive) {
                    delete(game)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("No saved games yet")
                .font(.headline)
                .foregroundColor(.black.opacity(0.85))
            Text("Play a game and it will appear here.")
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.055))
        )
    }

    private func delete(_ game: SavedChessGame) {
        games.removeAll { $0.id == game.id }
        repository.saveSavedGames(games)
    }
}

private struct SavedGameCard: View {
    let game: SavedChessGame
    let locked: Bool

    var body: some View {
        VStack(spacing: 8) {
            board
                .overlay {
                    if locked {
                        ZStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.52))
                            Image(systemName: "lock.fill")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundColor(.black.opacity(0.45))
                        }
                    }
                }

            Text(dateText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black.opacity(0.45))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .contentShape(Rectangle())
    }

    private var board: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            // Match BoardScene sizing (boardSize = 0.93 * side).
            let playableSide = side * 0.93
            let square = playableSide / 8

            ZStack {
                Image("Board")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: side, height: side)

                VStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<8, id: \.self) { column in
                                ZStack {
                                    if let piece = pieceAt(row: row, column: column) {
                                        Image(pieceAssetName(for: piece))
                                            .resizable()
                                            .interpolation(.high)
                                            .scaledToFit()
                                            // Match BoardScene piece size (pieceSize = 0.9 * cell).
                                            .padding(square * 0.05)
                                            .opacity(locked ? 0.35 : 0.85)
                                    }
                                }
                                .frame(width: square, height: square)
                            }
                        }
                    }
                }
                .frame(width: playableSide, height: playableSide)
            }
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var dateText: String {
        guard let createdAt = game.createdAt else { return "--/--/--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter.string(from: createdAt)
    }

    private func pieceAt(row: Int, column: Int) -> SavedChessGame.Piece? {
        guard game.finalBoard.indices.contains(row),
              game.finalBoard[row].indices.contains(column) else {
            return nil
        }
        return game.finalBoard[row][column]
    }

    private func pieceAssetName(for piece: SavedChessGame.Piece) -> String {
        "\(piece.type.rawValue)-\(piece.color.rawValue)"
    }
}

struct SavedGamesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SavedGamesView()
        }
    }
}
