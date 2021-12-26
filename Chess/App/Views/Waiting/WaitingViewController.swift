//
//  WaitingViewController.swift
//  Chess
//
//  Created by exerhythm on 10/9/21.
//

import UIKit

class WaitingViewController: UIViewController, OnlineGameDelegate {
    
    var socket: ChessWebsocket?
    var foundGame: StartOnlineGameViewController.FoundGame!
    var serverGame: ChessAPI.ServerGame?
    var username: String?
    
    @IBOutlet weak var progressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.progressView.setProgress(0.05, animated: true)
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            if self.progressView.progress >= 1 {
                timer.invalidate()
                // TODO: Remove the waiting room
            } else {
                self.progressView.setProgress(self.progressView.progress + 0.001, animated: false)
            }
        }
        
        socket = ChessWebsocket()
        socket!.connect(to: foundGame.code, difficulty: foundGame.difficulty)
        socket!.delegate = self
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! GameViewController
        vc.serverGame = serverGame
        vc.isOnline = true
        
        socket?.disconnect()
        
//        AppDelegate.instance.socket?.socket.write(string: "Sending", completion: nil)
//        AppDelegate.instance.socket?.delegate = vc
//        print(username)
//        print(serverGame)
    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        AppDelegate.instance.socket?.disconnect()
//    }
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    func gameReady() {
        socket?.disconnect()
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
//        navigationController?.popViewController(animated: true)
    }
    
    func onlineGameUserMovedPiece(move: NormalMove) { }
    
    func onlineGameUpdated(newGame: ChessAPI.ServerGame) {
        self.serverGame = newGame
        if newGame.players.count >= 2 {
            gameReady()
        }
    }
    
    func onlineGameUserReceivedWhiteID(_ id: String) {
        self.serverGame?.whiteID = id
    }
}
