//
//  ChessWebsocket.swift
//  Chess
//
//  Created by exerhythm on 12/20/21.
//

import Foundation
import Starscream

class ChessWebsocket: WebSocketDelegate {
    var socket: WebSocket!
    var isConnected: Bool = false
    weak var delegate: OnlineGameDelegate?
    
    func connect(to code: String, difficulty: ChessAPI.ServerGame.Difficulty?) {
        var url = URLComponents(url: ChessAPI.serverAddress.appendingPathComponent("channel"), resolvingAgainstBaseURL: false)
        url!.queryItems = [URLQueryItem(name: "id", value: code)]
        if let difficulty = difficulty {
            url!.queryItems!.append(URLQueryItem(name: "difficulty", value: difficulty.rawValue))
        }
        var request = URLRequest(url: url!.url!)
        request.timeoutInterval = 5
        request.addValue("Basic \(ChessAPI.base64Login())", forHTTPHeaderField: "Authorization")
        let pinner = FoundationSecurity(allowSelfSigned: true) // don't validate SSL certificates
        socket = WebSocket(request: request, certPinner: pinner)
        socket.delegate = self
        socket.connect()
    }
    func disconnect() {
        socket.disconnect()
    }
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            isConnected = true
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
                self?.socket.connect()
            })
        case .text(let string):
            print("Received text: \(string)")
            
            if let serverGame = try? JSONDecoder().decode(ChessAPI.ServerGame.self, from: string.data(using: .utf8)!) {
                delegate?.onlineGameUpdated(newGame: serverGame)
            } else if let msg = try? JSONDecoder().decode(PlayerJoinedMessage.self, from: string.data(using: .utf8)!) {
                if let id = msg.whiteID {
                    delegate?.onlineGameUserReceivedWhiteID(id)
                }
                delegate?.onlineGameUserJoined(username: msg.username)
            } else if let msg = try? JSONDecoder().decode(PlayerLeftMessage.self, from: string.data(using: .utf8)!) {
                delegate?.onlineGameUserLeft(username: msg.username)
            } else if let msg = try? JSONDecoder().decode(MoveMessage.self, from: string.data(using: .utf8)!) {
                delegate?.onlineGameUserMovedPiece(move: msg.move)
            }
            
            
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            isConnected = false
            break
        case .error(let error):
            isConnected = false
            if let error = error {
                delegate?.onlineGameHandleError(error)
            }
        }
    }
    func sendMove(_ move: NormalMove) {
        guard let data = try? JSONEncoder().encode(["move":move]) else { return }
        guard let text = String(data: data, encoding: .utf8) else { return }
        socket.write(string: text, completion: {
            print("Sent")
        })
    }
    func leave() {
        disconnect()
    }
    
    struct PlayerJoinedMessage: Codable {
        var playerJoinedMessage = true
        var username: String
        var whiteID: String?
    }
    struct PlayerLeftMessage: Codable {
        var playerLeftMessage = true
        var username: String
    }
    struct MoveMessage: Codable {
        var move: NormalMove
    }
    deinit {
        print("Deallocating websocket")
    }
}

protocol OnlineGameDelegate: AnyObject {
    func onlineGameHandleError(_ error: Error)
    func onlineGameUserJoined(username: String)
    func onlineGameUserLeft(username: String)
    func onlineGameUserMovedPiece(move: NormalMove)
    func onlineGameUserReceivedWhiteID(_ id: String)
    func onlineGameUpdated(newGame: ChessAPI.ServerGame)
}
