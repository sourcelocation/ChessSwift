//
//  RoomsViewController.swift
//  Chess
//
//  Created by exerhythm on 10/4/21.
//

import Foundation
import UIKit

//class RoomsViewController: UITableViewController {
//
//    var rooms: [ChessAPI.PublicGame] = []
//    var fetchTimer: Timer!
//
//    override func viewDidLoad() {
//        fetchTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(fetchRooms), userInfo: nil, repeats: true)
//
//        // Perhaps he's already in the room?
//        ChessAPI.myRoom { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let game):
//                    self.performSegue(withIdentifier: "ShowGame", sender: game)
//                case .failure(let error):
//                    self.fetchRooms()
//                    break
//                }
//            }
//        }
//    }
//
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        navigationController?.setNavigationBarHidden(false, animated: true)
//
//    }
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//
//        navigationController?.setNavigationBarHidden(true, animated: true)
//        fetchTimer.invalidate()
//    }
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if let game = sender as? ChessAPI.Game, let dest = segue.destination as? WaitingViewController {
//            dest.room = game
//        } else if let vc = segue.destination as? GameViewController {
//            let game = sender as! ChessAPI.Game
////            vc.setupOnlineGame(game: game)
//        }
//    }
//}
//
//extension RoomsViewController {
//    @objc func fetchRooms() {
//        ChessAPI.getRooms { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let games):
//                    self.rooms = games
//                    self.tableView.reloadData()
//                case .failure(let error):
//                    AppSnackBar.make(in: self.view, message: "An error occured. \(error.localizedDescription) Sorry for inconvenience.", duration: .custom(5)).show()
//                    print(error)
//                }
//            }
//        }
//    }
//}
//
//extension RoomsViewController {
//    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rooms.count }
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let room = rooms[indexPath.row]
//        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! RoomTableViewCell
//        cell.difficultyLabel.text = room.difficulty.localized()
//        return cell
//    }
//
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let room = rooms[indexPath.row]
//        guard let id = room.id else { return }
//        ChessAPI.joinRoom(id: id) { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let game):
//                    self.performSegue(withIdentifier: "ShowGame", sender: game)
//                case .failure(let error):
//                    AppSnackBar.make(in: self.view, message: "An error occured. \(error.localizedDescription) Sorry for inconvenience.", duration: .custom(5)).show()
//                    break
//                }
//            }
//        }
//    }
//}
