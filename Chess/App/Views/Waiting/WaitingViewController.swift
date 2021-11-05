//
//  WaitingViewController.swift
//  Chess
//
//  Created by exerhythm on 10/9/21.
//

import UIKit

class WaitingViewController: UIViewController {

    var timer: Timer!
    var room: ChessAPI.Game?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if room == nil {
            ChessAPI.newRoom(difficulty: .beginner) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let room):
                        self.room = room
                        
                        self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.sendOnline), userInfo: nil, repeats: true)
                    case .failure(let error):
                        
                        AppSnackBar(contextView: self.view, message: "Could not create a room. \(error)", duration: .custom(2)).show()
                    }
                }
            }
        }
    }
    
    @objc func sendOnline() {
        ChessAPI.sendOnlineStatus(completion: { result in
            switch result {
            case .success(_):
                break
            case .failure(let error):
                AppSnackBar(contextView: self.view, message: "Could not send an online status. \(error)", duration: .custom(2)).show()
            }
        })
        ChessAPI.myRoom { result in
            switch result {
            case .success(let game):
                self.room = game
            case .failure(let error):
                AppSnackBar(contextView: self.view, message: "Could not get the room. \(error)", duration: .custom(2)).show()
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
