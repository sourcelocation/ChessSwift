//
//  WaitingViewController.swift
//  Chess
//
//  Created by exerhythm on 10/9/21.
//

import UIKit
import Starscream

class WaitingViewController: UIViewController, WebSocketDelegate {
    var isConnected: Bool = false
    
    var socket: WebSocket!
//    var foundGame: StartOnlineGameViewController.FoundGame!
    var serverGame: ChessAPI.ServerGame?
    var username: String?
    var timer: Timer!
    
    var difficulty: ChessAPI.ServerGame.Difficulty?
    var code: ChessAPI.ServerGame.Difficulty?
    
    @IBOutlet weak var progressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.progressView.setProgress(0.05, animated: true)
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            if self.progressView.progress >= 1 {
                timer.invalidate()
                
                let alert = UIAlertController(title: "No players are currently online...".localized, message: "Try again later!".localized, preferredStyle: .alert)
                alert.addAction(.init(title: "OK".localized, style: .cancel, handler: { [weak self] button in
                    self?.navigationController?.popViewController(animated: true)
                }))
                alert.view.tintColor = #colorLiteral(red: 0.4086923003, green: 0.2684660256, blue: 0.1772648394, alpha: 1)
                self.present(alert, animated: true)
            } else {
                self.progressView.setProgress(self.progressView.progress + 0.001, animated: false)
            }
        }
        
        
        var url = URLComponents(url: ChessAPI.serverAddress.appendingPathComponent("waiting"), resolvingAgainstBaseURL: false)
//        url!.queryItems = [URLQueryItem(name: "id", value: code)]
        if let difficulty = difficulty {
            // TODO: Handle on server
            url!.queryItems = [URLQueryItem(name: "difficulty", value: difficulty.rawValue)]
        }
        var request = URLRequest(url: url!.url!)
        request.timeoutInterval = 5
        request.addValue("Basic \(ChessAPI.base64Login()!)", forHTTPHeaderField: "Authorization")
        let pinner = FoundationSecurity(allowSelfSigned: true) // don't validate SSL certificates
        socket = WebSocket(request: request, certPinner: pinner)
        socket.delegate = self
        socket.connect()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let vc = segue.destination as! GameViewController
//        vc.onlineGameCode = sender as? String
//        vc.isOnline = true
//        
//        socket?.disconnect()
//        timer.invalidate()
    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        AppDelegate.instance.socket?.disconnect()
//    }
    override func viewDidAppear(_ animated: Bool) {
        
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
            let code = string
            UserDefaults.standard.set(code, forKey: "GAME_CODE")
            performSegue(withIdentifier: "ShowGame", sender: code)
            
            
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
            print(error)
        }
    }
    
    deinit {
        print("deinit wait")
    }
}
