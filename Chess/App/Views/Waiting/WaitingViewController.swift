//
//  WaitingViewController.swift
//  Chess
//
//  Created by exerhythm on 10/9/21.
//

import UIKit

class WaitingViewController: UIViewController, OnlineGameDelegate {
    
    var foundGame: StartOnlineGameViewController.FoundGame!
    var socket: ChessWebsocket!
    var serverGame: ChessAPI.ServerGame?
    var username: String?
    
    @IBOutlet weak var progressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        socket = ChessWebsocket()
        socket.connect(to: foundGame.code, difficulty: foundGame.difficulty)
        socket.delegate = self
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if self.progressView.progress >= 1 {
                timer.invalidate()
                // TODO: Remove the waiting room
            } else {
                self.progressView.setProgress(self.progressView.progress + 0.001, animated: false)
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! GameViewController
        print(username)
        print(serverGame)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        socket.disconnect()
    }
    
    func gameReady() {
        performSegue(withIdentifier: "ShowGame", sender: username)
    }
    
    func onlineGameHandleError(_ error: Error) {
        print(error)
    }
    
    func onlineGameUserJoined(username: String) {
        self.username = username
        gameReady()
    }
    
    func onlineGameUserLeft(username: String) {
        navigationController?.popViewController(animated: true)
    }
    
    func onlineGameUserMovedPiece(move: NormalMove) { }

    func onlineGameReceivedServerGame(serverGame: ChessAPI.ServerGame) {
        self.serverGame = serverGame
        if serverGame.players.count >= 2 {
            gameReady()
        }
    }
    
}
