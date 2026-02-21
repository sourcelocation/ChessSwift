import Foundation
import CryptoKit

actor StockfishModelDownloader {
    struct DownloadError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    struct InstalledModels {
        let evalFile: URL
        let evalFileSmall: URL
    }

    static let shared = StockfishModelDownloader()

    private struct Model: Hashable {
        let optionName: String
        let fileName: String
        let minimumBytes: Int64
        let hashPrefix: String
    }

    private let models: [Model] = [
        .init(optionName: "EvalFile", fileName: "nn-1111cefa1111.nnue", minimumBytes: 1_000_000, hashPrefix: "1111cefa1111"),
        .init(optionName: "EvalFileSmall", fileName: "nn-37f18f62d772.nnue", minimumBytes: 250_000, hashPrefix: "37f18f62d772")
    ]

    func ensureModels(progress: @escaping (Double) -> Void) async throws -> InstalledModels {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        else {
            throw DownloadError(message: "Unable to access Application Support directory")
        }
        let directory = try modelsDirectory(in: appSupport)

        var urls: [String: URL] = [:]
        for (index, model) in models.enumerated() {
            let fileURL = directory.appendingPathComponent(model.fileName)
            let start = Double(index) / Double(models.count)
            let end = Double(index + 1) / Double(models.count)
            try await ensureModel(model, at: fileURL) { local in
                progress(start + ((end - start) * local))
            }
            urls[model.optionName] = fileURL
        }

        await MainActor.run { progress(1.0) }

        guard let evalFile = urls["EvalFile"], let evalFileSmall = urls["EvalFileSmall"] else {
            throw DownloadError(message: "Missing downloaded model files")
        }
        return InstalledModels(evalFile: evalFile, evalFileSmall: evalFileSmall)
    }

    private func modelsDirectory(in appSupport: URL) throws -> URL {
        let modelDirectory = appSupport
            .appendingPathComponent("Chess", isDirectory: true)
            .appendingPathComponent("Models", isDirectory: true)
        if !FileManager.default.fileExists(atPath: modelDirectory.path) {
            try FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
        }
        return modelDirectory
    }

    private func ensureModel(_ model: Model, at fileURL: URL, progress: @escaping (Double) -> Void) async throws {
        if try isValidModel(model, at: fileURL) {
            await MainActor.run { progress(1.0) }
            return
        }
        try await downloadModel(model, to: fileURL, progress: progress)
        guard try isValidModel(model, at: fileURL) else {
            throw DownloadError(message: "Downloaded model failed validation: \(model.fileName)")
        }
    }

    private func isValidModel(_ model: Model, at url: URL) throws -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else { return false }
        let size = try fileSize(at: url)
        guard size >= model.minimumBytes else { return false }
        let prefix = try sha256HexPrefix(for: url, length: model.hashPrefix.count)
        return prefix.caseInsensitiveCompare(model.hashPrefix) == .orderedSame
    }

    private func downloadModel(_ model: Model, to destinationURL: URL, progress: @escaping (Double) -> Void) async throws {
        let remoteURL = URL(string: "https://github.com/official-stockfish/networks/raw/refs/heads/master/\(model.fileName)")!
        let tempURL = destinationURL.appendingPathExtension("download")
        try? FileManager.default.removeItem(at: tempURL)
        FileManager.default.createFile(atPath: tempURL.path, contents: nil)

        guard let handle = try? FileHandle(forWritingTo: tempURL) else {
            throw DownloadError(message: "Unable to create temporary file")
        }

        defer { try? handle.close() }

        let headExpectedLength = try await expectedContentLength(for: remoteURL)
        let (bytes, response) = try await URLSession.shared.bytes(from: remoteURL)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            try? FileManager.default.removeItem(at: tempURL)
            throw DownloadError(message: "Failed to download \(model.fileName)")
        }

        let expectedLength = max(response.expectedContentLength, headExpectedLength ?? -1)
        var received: Int64 = 0
        var lastProgressEmittedAt: Int64 = 0
        var buffer = Data()
        buffer.reserveCapacity(64 * 1024)

        do {
            for try await byte in bytes {
                buffer.append(byte)
                received += 1

                if buffer.count >= 64 * 1024 {
                    try handle.write(contentsOf: buffer)
                    buffer.removeAll(keepingCapacity: true)
                }

                if expectedLength > 0, received - lastProgressEmittedAt >= 64 * 1024 {
                    lastProgressEmittedAt = received
                    let pct = min(0.999, Double(received) / Double(expectedLength))
                    await MainActor.run { progress(pct) }
                }
            }
            if !buffer.isEmpty {
                try handle.write(contentsOf: buffer)
            }
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            throw error
        }

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        await MainActor.run { progress(1.0) }
    }

    private func fileSize(at url: URL) throws -> Int64 {
        (try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value ?? 0
    }

    private func expectedContentLength(for remoteURL: URL) async throws -> Int64? {
        var request = URLRequest(url: remoteURL)
        request.httpMethod = "HEAD"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode)
        else {
            return nil
        }

        if let contentLength = http.value(forHTTPHeaderField: "Content-Length"),
           let bytes = Int64(contentLength),
           bytes > 0 {
            return bytes
        }
        return nil
    }

    private func sha256HexPrefix(for fileURL: URL, length: Int) throws -> String {
        guard let stream = InputStream(url: fileURL) else {
            throw DownloadError(message: "Unable to read model for verification")
        }
        stream.open()
        defer { stream.close() }

        var hasher = SHA256()
        let bufferSize = 64 * 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read < 0 {
                throw DownloadError(message: "Failed reading downloaded model")
            }
            if read == 0 { break }
            hasher.update(data: Data(bytes: buffer, count: read))
        }

        let digest = hasher.finalize()
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return String(hex.prefix(length))
    }
}
