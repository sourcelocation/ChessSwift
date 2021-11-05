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
    }
    
    private static let serverAddress = URL(string: "http://localhost:5432")
    
    private static var login: Login? {
        get {
            guard let data = UserDefaults.standard.data(forKey: "LOGIN") else { return nil }
            return try? JSONDecoder().decode(Login.self, from: data)
        } set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            UserDefaults.standard.set(data, forKey: "LOGIN")
        }
    }
    
    static func getRooms(completion: @escaping (Result<[PublicGame], Error>) -> Void) {
        guard let address = serverAddress?.appendingPathComponent("/rooms") else {
            completion(.failure(Errors.invalidURL))
            return
        }
        request(url: address, method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let games = try JSONDecoder().decode([PublicGame].self, from: data)
                    completion(.success(games))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
                print(error)
            }
        }
    }
    
    static func newRoom(difficulty: Difficulty, completion: @escaping (Result<Game, Error>) -> Void) {
        guard let address = serverAddress?.appendingPathComponent("/rooms") else { completion(.failure(Errors.invalidURL)); return }
        
        let bodyData = try? JSONEncoder().encode(PublicGame(id: nil, state: .waiting, difficulty: difficulty, time: 300))
        request(url: address, method: .post, body: bodyData) { result in
            switch result {
            case .success(let data):
                do {
                    let game = try JSONDecoder().decode(Game.self, from: data)
                    completion(.success(game))
                } catch {
                    print(error)
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
                print(error)
            }
        }
    }
    
    static func myRoom(completion: @escaping (Result<Game, Error>) -> Void) {
        guard let address = serverAddress?.appendingPathComponent("/rooms/my") else { completion(.failure(Errors.invalidURL)); return }
        
        request(url: address, method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let game = try JSONDecoder().decode(Game.self, from: data)
                    completion(.success(game))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
                print(error)
            }
        }
    }
    
    static func sendOnlineStatus(completion: @escaping (Result<String, Error>) -> Void) {
        guard let address = serverAddress?.appendingPathComponent("/online") else {
            return
        }
        request(url: address, method: .post) { result in
            switch result {
            case .success(let data):
                guard let str = String(data: data, encoding: .utf8) else { completion(.failure(Errors.incorrectFormat)); return }
                completion(.success(str))
            case .failure(let error):
                completion(.failure(error))
                print(error)
                return
            }
        }
    }
    
    private static func getLogin(completion: @escaping (Result<Login, Error>) -> Void) {
        if let login = login {
            completion(.success(login))
        } else {
            register { result in
                switch result {
                case .success(let login):   
                    self.login = login
                    completion(.success(login))
                case .failure(let error):
                    completion(.failure(error))
                    print(error)
                    return
                }
            }
        }
    }
    
    private static func register(completion: @escaping (Result<Login, Error>) -> Void) {
        guard let address = serverAddress?.appendingPathComponent("/newAccount") else {
            completion(.failure(Errors.invalidURL))
            return
        }
        request(url: address, method: .post, withAuth: false) { result in
            switch result {
            case .success(let data):
                do {
                    let login = try JSONDecoder().decode(Login.self, from: data)
                    completion(.success(login))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                print(error)
                completion(.failure(error))
            }
        }
    }
    
    
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case patch = "PATCH"
    }
}

extension ChessAPI {
    private static func request(url: URL, method: HTTPMethod, body: Data? = nil, withAuth: Bool = true, completion: @escaping (Result<Data, Error>) -> Void) {
        func sendRequest(login: Login?) {
            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.httpMethod = method.rawValue
            request.httpBody = body
            
            if withAuth {
                guard let loginData = "\(login!.username):\(login!.key)".data(using: String.Encoding.utf8) else { return }
                let loginBase64 = loginData.base64EncodedString()
                request.addValue("Basic \(loginBase64)", forHTTPHeaderField: "Authorization")
            }
            
            URLSession.shared.dataTask(with: request) { data, result, error in
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
            getLogin { login in
                switch login {
                case .success(let login):
                    sendRequest(login: login)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            sendRequest(login: nil)
        }
    }
}
