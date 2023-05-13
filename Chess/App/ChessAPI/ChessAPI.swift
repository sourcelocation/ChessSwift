//
//  ChessAPI.swift
//  Chess
//
//  Created by exerhythm on 10/1/21.
//

import Foundation

class ChessAPI {
    enum Errors: Error {
        case invalidURL
        case incorrectFormat
        case unauthorized
    }

    static let serverAddress = URL(string: "http://home.sourceloc.net:5432")!

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case patch = "PATCH"
    }
}

extension ChessAPI {
    static func base64Login() -> String? {
        guard let login = login else { return nil }
        guard let loginData = "\(login.username):\(login.passwordHash)".data(using: String.Encoding.utf8) else { return "" }
        return loginData.base64EncodedString()
    }
    private static func request(url: URL, method: HTTPMethod, body: Data? = nil, withAuth: Bool = true, completion: @escaping (Result<Data, Error>) -> Void) {
        func sendRequest(login: Login?) {
            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.httpMethod = method.rawValue
            request.httpBody = body

            if withAuth {
                guard let login = login else { return }
                guard let loginData = "\(login.username):\(login.passwordHash)".data(using: String.Encoding.utf8) else { return }
                let loginBase64 = loginData.base64EncodedString()
                request.addValue("Basic \(loginBase64)", forHTTPHeaderField: "Authorization")
            }

            URLSession.shared.dataTask(with: request) { data, result, error in
                if (result as? HTTPURLResponse)?.statusCode == 401 {
                    logout()
                }
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let data = data else { return }
                if let str = String(data: data, encoding: .utf8), str.contains("error") { // TODO: Better error checking
                    completion(.failure(Errors.incorrectFormat))
                }
                
                completion(.success(data))
            }.resume()
        }
        if withAuth {
            sendRequest(login: login)
        } else {
            sendRequest(login: nil)
        }
    }
}

// MARK: - Logins -
extension ChessAPI {
    static var login: Login? {
        get {
            guard let data = UserDefaults.standard.data(forKey: "LOGIN") else { return nil }
            return try? JSONDecoder().decode(Login.self, from: data)
        } set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            UserDefaults.standard.set(data, forKey: "LOGIN")
        }
    }
    static func logout() {
        UserDefaults.standard.set(nil, forKey: "LOGIN")
    }

    static func register(username: String, completion: @escaping (Result<Login, Error>) -> Void) {
        let address = serverAddress.appendingPathComponent("/newAccount")
        print(address.absoluteString)
        request(url: address, method: .post, body: try? JSONEncoder().encode(["username":username]), withAuth: false) { result in
            switch result {
            case .success(let data):
                do {
                    login = try JSONDecoder().decode(Login.self, from: data)
                    completion(.success(login!))
                } catch {
                    print(error)
                    completion(.failure(error))
                }
            case .failure(let error):
                print(error)
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Games -
extension ChessAPI {
    static func findGame(difficulty: ServerGame.Difficulty, completion: @escaping (Result<String, Error>) -> Void) {
        let address = serverAddress.appendingPathComponent("/games/find")
        print(address.absoluteString)
        let data = try? JSONEncoder().encode(["difficulty":difficulty])
        request(url: address, method: .post, body: data) { result in
            switch result {
            case .success(let data):
                do {
                    guard let code = String(data: data, encoding: .utf8) else { throw(Errors.incorrectFormat) }
                    completion(.success(code))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                print(error)
                completion(.failure(error))
            }
        }
    }
    
    static func isGameStillRunning(code: String, completion: @escaping (Bool) -> Void) {
        let address = serverAddress.appendingPathComponent("/games/state/\(code)")
        print(address.absoluteString)
        request(url: address, method: .get) { result in
            switch result {
            case .success(let data):
                completion(Bool(String(data: data, encoding: .utf8) ?? "false") ?? false)
            case .failure(let error):
                print(error)
                completion(false)
            }
        }
    }
}
