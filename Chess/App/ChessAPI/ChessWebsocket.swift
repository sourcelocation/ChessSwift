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
    var delegate: OnlineGameDelegate?
    
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
        case .text(let string):
            struct PlayerJoinedMessage: Codable {
                var playerJoinedMessage: String
                var username: String
            }
            print("Received text: \(string)")
            
            if let serverGame = try? JSONDecoder().decode(ChessAPI.ServerGame.self, from: string.data(using: .utf8)!) {
                delegate?.onlineGameReceivedServerGame(serverGame: serverGame)
            } else if let playerJoinedMessage = try? JSONDecoder().decode(PlayerJoinedMessage.self, from: string.data(using: .utf8)!) {
                delegate?.onlineGameUserJoined(username: playerJoinedMessage.username)
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
        case .error(let error):
            isConnected = false
            if let error = error {
                delegate?.onlineGameHandleError(error)
            }
        }
    }
}

protocol OnlineGameDelegate {
    func onlineGameHandleError(_ error: Error)
    func onlineGameUserJoined(username: String)
    func onlineGameUserLeft(username: String)
    func onlineGameUserMovedPiece(move: NormalMove)
    func onlineGameReceivedServerGame(serverGame: ChessAPI.ServerGame)
}
