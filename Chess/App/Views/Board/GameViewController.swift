//
//  GameViewController.swift
//  Chess
//
//  Created by Матвей Анисович on 4/4/21.
//

import UIKit
import SpriteKit
import StoreKit
import SnackBar
import SwiftMessages
import AVFoundation
import SwiftUI

class GameViewController: UIViewController, GameUIDelegate {
    
    var board: BoardScene?
    
    var isOnline: Bool = false
    var serverGame: ChessAPI.ServerGame?
    var socket: ChessWebsocket?
    
    var undos: Int { // For free users
        get { UserDefaults.standard.integer(forKey: "undos") }
        set { UserDefaults.standard.set(newValue, forKey: "undos") }
    }
    var clockWhite = 0.0 {
        didSet { UserDefaults.standard.setValue(clockWhite, forKey: "clockWhite") }
    }
    var clockBlack = 0.0 {
        didSet { UserDefaults.standard.setValue(clockBlack, forKey: "clockBlack") }
    }
    
    private var clockEnabled: Bool {
        get { !isOnline && UserDefaults.standard.bool(forKey: "clockEnabled") }
        set { UserDefaults.standard.setValue(newValue, forKey: "clockEnabled") }
    }
    
    var timerWhite: Timer?
    var timerBlack: Timer?
    var whiteDidMove = false
    var blackDidMove = false
    var clockTime: Double {
        return Double(UserDefaults.standard.integer(forKey: "clockSelectedMinutes") * 60)
    }
    var clockBorderWidth: CGFloat {
        if self.traitCollection.verticalSizeClass != self.traitCollection.horizontalSizeClass {
            return 2.5
        } else {
            return 3.5
        }
    }
    var noRules: Bool { return !isOnline && UserDefaults.standard.bool(forKey: "noRules") }
    var autoClock: Bool { return UserDefaults.standard.bool(forKey: "autoClock") }
    
    var clockSwitchPlayer: AVAudioPlayer?
    var landscapeOrientation: Bool = false
    var isLoadingVC = true
    
    @IBOutlet weak var menu: UIStackView!
    @IBOutlet weak var boardView: UIView!
    
    @IBOutlet var leftMenuConstraints: [NSLayoutConstraint]!
    @IBOutlet var rightMenuConstraints: [NSLayoutConstraint]!
    
    @IBOutlet weak var clockButtonWhite: UIButton!
    @IBOutlet weak var clockButtonBlack: UIButton!
    @IBOutlet weak var clockLabelWhite: UILabel!
    @IBOutlet weak var clockLabelBlack: UILabel!
    @IBOutlet weak var clock: UIStackView!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var proButton: UIButton!
    @IBOutlet weak var editButtonsStack: UIStackView!
    
    
    @IBOutlet var noRulesEditorPieces: [UIImageView]!
    
    @IBAction func whiteClockTapped(_ sender: UIButton) {
        if whiteDidMove {
            stopTimers()
            startBlackTimer()
            playClockSound()
        }
    }
    @IBAction func blackClockTapped(_ sender: UIButton) {
        if blackDidMove {
            stopTimers()
            startWhiteTimer()
            playClockSound()
        }
    }
    
    @IBAction func undoButtonPressed(_ sender: UIButton) {
        if !board!.game.history.isEmpty {
            if undos < 5 || UserDefaults.standard.bool(forKey: "pro") {
                undos += 1
                board?.game.undo(noRulesEnabled: noRules)
                board?.deselectPiece()
                board?.saveGame()
                stopTimers()
            } else {
                showProVersionVC()
            }
        }
    }
    @IBAction func premiumVersionButtonTapped(_ sender: UIButton) {
        showProVersionVC()
    }
    @IBAction func restartButtonPressed(_ sender: UIButton) {
        if !isOnline {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Start a new game?", message: "Are you sure you want to start a new game?", preferredStyle: .actionSheet)
                alert.addAction(.init(title: "Cancel", style: .cancel))
                alert.addAction(.init(title: "Restart", style: .default, handler: { [weak self] _ in
                    guard let self = self else { return }
                    self.board!.restart()
                    if abs((UIApplication.shared.delegate as! AppDelegate).startTime.timeIntervalSince(Date())) > 750 {
                        self.showRatingView()
//                        AppDelegate.review()
                    }
                    self.undos = 0
                    self.resetClockValues()
                    self.board?.saveGame()
                }))
                alert.view.tintColor = #colorLiteral(red: 0.4086923003, green: 0.2684660256, blue: 0.1772648394, alpha: 1)
                if let popoverController = alert.popoverPresentationController {
                    popoverController.sourceView = sender
                }
                self.present(alert, animated: true)
            }
        } else {
            let alert = UIAlertController(title: "Surrender?", message: "Are you sure you want to surrender and leave this game?", preferredStyle: .alert)
            alert.addAction(.init(title: "Cancel", style: .cancel))
            alert.addAction(.init(title: "Surrender", style: .destructive, handler: { [weak self]_ in
                self?.navigationController?.popToRootViewController(animated: true)
            }))
            alert.view.tintColor = #colorLiteral(red: 0.4086923003, green: 0.2684660256, blue: 0.1772648394, alpha: 1)
            present(alert, animated: true)
        }
    }
    @IBAction func backButtonTapped(_ sender: UIButton) {
        if isOnline {
            socket?.leave()
        }
        navigationController?.popToRootViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for imageView in noRulesEditorPieces {
            if imageView.tag >= 5 {
                imageView.transform = CGAffineTransform(rotationAngle: .pi)
            }
        }
        toggleEditor(on: noRules)
        
        
        if isOnline {
            backButton.setImage(UIImage(systemName: "flag")!, for: [])
            editButtonsStack.isHidden = true
            proButton.isHidden = true
            setupForOnlineGame(board: serverGame!.chessGame!.normalBoard(), playingAsWhite: serverGame?.whiteID == ChessAPI.login?.id.uuidString)
            
        } else {
            setupForOfflineGame()
        }
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setNeedsUpdateOfHomeIndicatorAutoHidden()
        
        clockLabelBlack.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        clockLabelWhite.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        if #available(iOS 13.0, *) {
            clockLabelWhite.font = UIFont(descriptor: clockLabelWhite.font.fontDescriptor.withDesign(.rounded)!, size: 24)
            clockLabelBlack.font = UIFont(descriptor: clockLabelBlack.font.fontDescriptor.withDesign(.rounded)!, size: 24)
        } else {
            clockLabelWhite.font = UIFont.systemFont(ofSize: 24)
            clockLabelBlack.font = UIFont.systemFont(ofSize: 24)
        }
        clockWhite = UserDefaults.standard.double(forKey: "clockWhite") == 0 ? self.clockTime : UserDefaults.standard.double(forKey: "clockWhite")
        clockBlack = UserDefaults.standard.double(forKey: "clockBlack") == 0 ? self.clockTime : UserDefaults.standard.double(forKey: "clockBlack")
        clockLabelWhite.text = formatTimeToString(clockWhite)
        clockLabelBlack.text = formatTimeToString(clockBlack)
        
        let borderColor = UIColor(red: 0.6601, green: 0.5078, blue: 0.3867, alpha: 1).cgColor
        clockButtonWhite.layer.borderColor = borderColor
        clockButtonBlack.layer.borderColor = borderColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.checkForCrash()
            UserDefaults.standard.set(true, forKey: "didntEndSession")
        })
        
        clockSwitchPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "ClockSwitched", withExtension: "wav")!)
        toggleClock(on: !isInPortrait && clockEnabled)
        
        if #available(iOS 13.0, *) { } else {
            self.undos = 9999999
            self.board?.proVersion = true
            UserDefaults.standard.set(true,forKey: "pro")
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isLoadingVC, !isOnline {
            loadBoard()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            guard noRules, landscapeOrientation, !isOnline else { return }
            for imageView in noRulesEditorPieces {
                let location = touch.location(in: view)
                if !(imageView.globalFrame?.contains(location) ?? false) { continue }
                let i = imageView.tag
                
                var pieceType: ChessPieceType!
                var pieceColor: ChessPieceColor!
                switch i {
                case 0,5: pieceType = .pawn
                case 1,6: pieceType = .knight
                case 2,7: pieceType = .bishop
                case 3,8: pieceType = .rook
                case 4,9: pieceType = .queen
                default: pieceType = .pawn }
                switch i {
                case 0...4: pieceColor = .white
                case 5...9: pieceColor = .black
                default: pieceColor = .white }
                
                board?.createPiece(pieceType: pieceType, pieceColor: pieceColor)
                break
            }
        }
    }
    
    func loadBoard() {
        board = BoardScene(size: boardView.frame.size)
        board!.vc = self
        board!.vcDelegate = self
        board!.scaleMode = .aspectFill
        board!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        if let view = self.boardView as! SKView? {
            view.presentScene(board)
            view.ignoresSiblingOrder = true
            view.showsFPS = false
            view.showsNodeCount = false
        }
        
        board?.restart(overrideSave: !isOnline)
        landscapeOrientation = !isInPortrait
        toggleClock(on: !isInPortrait && clockEnabled)
        
        isLoadingVC = false
    }
    
    func setupForOfflineGame() {
        loadBoard()
        board?.loadGame()
    }
    func setupForOnlineGame(board: [[ChessPiece?]], playingAsWhite: Bool) {
        loadBoard()
        self.board?.setupGame(customBoard: board)
        self.board?.allowMovesOnlyFromColor = playingAsWhite ? .white : .black
        self.board?.view?.transform =  CGAffineTransform(rotationAngle: playingAsWhite ? 0 : .pi)
        
        connectWebsocket()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        
        // Top notification
        let view = MessageView.viewFromNib(layout: .cardView)
        if let user = serverGame?.players.filter({ player1 in
            return ChessAPI.login?.username != player1.username
        }).first {
            // Not always called...
            view.configureContent(title: "The game has started!", body: "Your opponent: \(user.username)", iconText: "🚩")
            view.button?.isHidden = true
            
            var config = SwiftMessages.Config()
            config.duration = .seconds(seconds: 5)
            SwiftMessages.show(config: config, view: view)
        }
    }
    func setupForComputerGame() {
        // TODO: Computer
    }
    
    func showProVersionVC() {
        if #available(iOS 13.0.0, *) {
            let vc = UIHostingController(rootView: PremiumView(dismissAction: {self.dismiss( animated: true, completion: nil )}))
            present(vc, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination as! UINavigationController
        let settings = dest.viewControllers[0] as! SettingsViewController
        settings.vc = self
    }
    
    func movedPiece(color: ChessPieceColor, move: NormalMove) {
        if clockEnabled {
            if color == .white {
                whiteDidMove = true
                
                if !autoClock {
                    startWhiteTimer()
                } else {
                    stopTimers()
                    startBlackTimer()
                }
            } else {
                blackDidMove = true
                if !autoClock {
                    startBlackTimer()
                } else {
                    stopTimers()
                    startWhiteTimer()
                }
            }
            if !autoClock {
                board!.canMove = false
            }
        }
        
        if isOnline {
            let piece = board!.game.piece(at: move.toPos)
            guard !(piece!.pieceType == .pawn && (move.toPos.y == (piece!.pieceColor == .white ? 0 : 7))) else { return }
            socket!.sendMove(move)
        }
    }
    
    
    func toggleEditor(on: Bool) {
        noRulesEditorPieces.forEach { image in
            image.isHidden = !on
        }
    }
    
    
    // MARK: - Clock -
    fileprivate func startWhiteTimer() {
        clockButtonWhite.layer.borderWidth = clockBorderWidth
        if !(timerWhite?.isValid ?? false) {
            timerWhite = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(fireWhiteTimer), userInfo: nil, repeats: true)
        }
    }
    fileprivate func startBlackTimer() {
        clockButtonBlack.layer.borderWidth = clockBorderWidth
        if !(timerBlack?.isValid ?? false) {
            timerBlack = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(fireBlackTimer), userInfo: nil, repeats: true)
        }
    }
    @objc func fireWhiteTimer() {
        clockWhite -= 0.1
        clockLabelWhite.text = formatTimeToString(clockWhite)
        
        if clockWhite <= 0 {
            let alert = UIAlertController(title: "Black wins! (Time ran out)", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue without a clock", style: .cancel, handler: { [weak self] _ in
                guard let self = self else { return }
                self.toggleClock(on: false)
            }))
            alert.addAction(UIAlertAction(title: "Start a new game", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                self.board!.restart()
                self.undos = 0
                self.resetClockValues()
                self.board?.saveGame()
            }))
            // TODO: 1 more minute!!! :))))
            alert.view.tintColor = #colorLiteral(red: 0.4086923003, green: 0.2684660256, blue: 0.1772648394, alpha: 1)
            present(alert, animated: true)
            stopTimers()
        }
    }
    @objc func fireBlackTimer() {
        clockBlack -= 0.1
        clockLabelBlack.text = formatTimeToString(clockBlack)
        
        if clockBlack <= 0 {
            let alert = UIAlertController(title: "White wins! (Time ran out)", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue without a clock", style: .cancel, handler: { [weak self] _ in
                self?.toggleClock(on: false)
            }))
            alert.addAction(UIAlertAction(title: "Start a new game", style: .default, handler: { [weak self]  _ in
                guard let self = self else { return }
                self.board!.restart()
                self.undos = 0
                self.resetClockValues()
                self.board?.saveGame()
            }))
            alert.view.tintColor = #colorLiteral(red: 0.4086923003, green: 0.2684660256, blue: 0.1772648394, alpha: 1)
            present(alert, animated: true)
            stopTimers()
        }
    }
    func toggleClock(on: Bool) {
        if landscapeOrientation {
            if on {
                NSLayoutConstraint.deactivate(leftMenuConstraints)
                NSLayoutConstraint.deactivate(rightMenuConstraints)
                NSLayoutConstraint.activate(leftMenuConstraints)
                
                clockEnabled = true
                clock.isHidden = false
                clock.alpha = 1
                return
            } else {
                NSLayoutConstraint.deactivate(rightMenuConstraints)
                NSLayoutConstraint.deactivate(leftMenuConstraints)
                
                NSLayoutConstraint.activate(rightMenuConstraints)
            }
        }
        clockEnabled = false
        self.stopTimers()
        clock.isHidden = true
        clock.alpha = 0
        self.board!.canMove = true
    }
    func stopTimers() {
        self.timerWhite?.invalidate()
        self.timerBlack?.invalidate()
        self.board!.canMove = true
        self.whiteDidMove = false
        self.blackDidMove = false
        clockButtonWhite.layer.borderWidth = 0
        clockButtonBlack.layer.borderWidth = 0
    }
    
    func resetClockValues() {
        clockWhite = clockTime
        clockBlack = clockTime
        stopTimers()
        clockLabelWhite.text = formatTimeToString(clockWhite)
        clockLabelBlack.text = formatTimeToString(clockBlack)
    }
    func formatTimeToString(_ time: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.second, .minute]
        formatter.zeroFormattingBehavior = [ .pad ]
        return formatter.string(from: time) ?? "5:00"
    }
    
    func bounceTimer() {
        if whiteDidMove {
            clockButtonWhite.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            UIView.animate(withDuration: 2.0, delay: 0, usingSpringWithDamping: CGFloat(0.20), initialSpringVelocity: CGFloat(6.0), options: UIView.AnimationOptions.allowUserInteraction, animations: { [weak self] in
                self?.clockButtonWhite?.transform = CGAffineTransform.identity
            })
        } else {
            clockButtonBlack.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            UIView.animate(withDuration: 2.0, delay: 0, usingSpringWithDamping: CGFloat(0.20), initialSpringVelocity: CGFloat(6.0), options: UIView.AnimationOptions.allowUserInteraction, animations: { [weak self] in
                self?.clockButtonBlack?.transform = CGAffineTransform.identity
            })
        }
    }
    fileprivate func playClockSound() {
        if !board!.noSounds {
            clockSwitchPlayer!.play()
        }
    }
    
    var aliveSince = Date() // Online
    
    deinit {
        print("Board deinit")
    }
}
extension GameViewController: OnlineGameDelegate {
    func onlineGameHandleError(_ error: Error) {
        
    }
    
    func onlineGameUserJoined(username: String) {
        if abs(aliveSince.distance(to: Date())) > 2 {
            let view = MessageView.viewFromNib(layout: .cardView)
            view.configureContent(title: "Opponent reconnected to the game", body: "", iconText: "⚔️")
            view.button?.isHidden = true
            
            var config = SwiftMessages.Config()
            config.duration = .seconds(seconds: 2)
            SwiftMessages.show(config: config, view: view)
        } else {
            // Top notification
            let view = MessageView.viewFromNib(layout: .cardView)
            view.configureContent(title: "The game has started!", body: "Your opponent: \(username)", iconText: "🚩")
            view.button?.isHidden = true
            
            var config = SwiftMessages.Config()
            config.duration = .seconds(seconds: 5)
            SwiftMessages.show(config: config, view: view)
        }
    }
    
    func onlineGameUserLeft(username: String) {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureContent(title: "Opponent has left", body: "You can wait him to come back or leave now", iconText: "🚪")
        view.button?.isHidden = true
        
        var config = SwiftMessages.Config()
        config.duration = .seconds(seconds: 5)
        SwiftMessages.show(config: config, view: view)
    }
    
    func onlineGameUserMovedPiece(move: NormalMove) {
        board?.perform(move: move)
    }
    
    func onlineGameUserReceivedWhiteID(_ id: String) {
        
    }
    
    func onlineGameUpdated(newGame: ChessAPI.ServerGame) {
        
    }
    
    @objc fileprivate func applicationDidBecomeActive() {
        print("Re-connect")
        connectWebsocket()
    }
    
    fileprivate func connectWebsocket() {
        if !(socket?.isConnected ?? false) {
            socket?.disconnect()
            socket = ChessWebsocket()
            socket!.connect(to: serverGame!.id, difficulty: serverGame!.difficulty)
            socket!.delegate = self
        }
    }
}
// MARK: - Other -
extension GameViewController {
    func checkForCrash() {
        #if DEBUG
        print("Cannot send a crash report in the DEBUG environment")
        #else
        if UserDefaults.standard.bool(forKey: "didntEndSession") {
            var request = URLRequest(url: URL(string: "http://92.61.67.58:4041/crashes")!)
            request.httpMethod = "POST"
            
            if let data = UserDefaults.standard.data(forKey: "History") {
                let dateFormatter = DateFormatter()
                let postData = try? JSONSerialization.data(withJSONObject: [
                    "history": String(data: data, encoding: .utf8) ?? "No history",
                    "version": (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "No version",
                    "date": dateFormatter.string(from: Date()),
                ], options: [])
                request.httpBody = postData
            }
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            URLSession.shared.dataTask(with: request,completionHandler: { data, response, error in
                print("Sent crash report!")
            })
            .resume()
            self.board?.restart()
        }
        #endif
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.bottom]
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: { [weak self] in
            guard let self = self else { return}
            self.landscapeOrientation = size.width > self.view.frame.size.width// UIApplication.shared.windows.first?.windowScene?.interfaceOrientation == .landscapeLeft || UIApplication.shared.windows.first?.windowScene?.interfaceOrientation == .landscapeRight// size.width > size.height //UIDevice.current.orientation.isLandscape
            self.toggleClock(on: UIDevice.current.orientation.isLandscape && self.clockEnabled)
            self.loadBoard()
        })
    }
    func showRatingView() {
        if !UserDefaults.standard.bool(forKey: "reviewed") {
            let view: EnjoymentView = try! SwiftMessages.viewFromNib()
            view.yesAction = { AppDelegate.review(); SwiftMessages.hide() }
            view.noAction = { SwiftMessages.hide(); UserDefaults.standard.set(true, forKey: "reviewed") }
            var config = SwiftMessages.defaultConfig
            config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)
            config.duration = .forever
            config.presentationStyle = .bottom
            config.dimMode = .gray(interactive: true)
            SwiftMessages.show(config: config, view: view)
        }
    }
}

protocol GameUIDelegate: AnyObject {
    func movedPiece(color: ChessPieceColor, move: NormalMove)
    func bounceTimer()
}

extension UIView{
    var globalPoint :CGPoint? {
        return self.superview?.convert(self.frame.origin, to: nil)
    }
    var globalFrame :CGRect? {
        return self.superview?.convert(self.frame, to: nil)
    }
}
