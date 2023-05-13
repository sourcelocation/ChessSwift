//
//  StartOnlineGameViewController.swift
//  Chess
//
//  Created by exerhythm on 12/20/21.
//

import UIKit

class StartOnlineGameViewController: UIViewController {

    let difficulties: [ChessAPI.ServerGame.Difficulty] = [.beginner,.intermediate,.advanced]
    
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var picker: UIPickerView!
    
    @IBOutlet weak var findPlayerButton: UIButton!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var createButton: UIButton!
    
    @IBAction func findButtonTapped(_ sender: UIButton) {
        func showRegistration(taken: Bool = false) {
            let alert = UIAlertController(title: (taken ? "Sorry, this username has already been taken.".localized + " " : "") + "Please type in your username".localized, message: nil, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.placeholder = "Username".localized
                textField.tintColor = #colorLiteral(red: 0.4086923003, green: 0.2684660256, blue: 0.1772648394, alpha: 1)
            }
            alert.view.tintColor = #colorLiteral(red: 0.4086923003, green: 0.2684660256, blue: 0.1772648394, alpha: 1)
            alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
            alert.addAction(UIAlertAction(title: "Register".localized, style: .default, handler: { _ in
                if let text = alert.textFields![0].text, !text.isEmpty {
                    ChessAPI.register(username: text, completion: { result in
                        DispatchQueue.main.async { [weak self] in
                            switch result {
                            case .failure(_):
                                showRegistration(taken: true)
                            case .success(_):
                                self?.findGame()
                            }
                        }
                    })
                }
            }))
            present(alert, animated: true)
        }
        if ChessAPI.login == nil {
            showRegistration()
        } else {
            findGame()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        picker.dataSource = self
        
        codeTextField.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))

        view.addGestureRecognizer(tap)
        
        if let previousCode = UserDefaults.standard.string(forKey: "GAME_CODE") {
            ChessAPI.isGameStillRunning(code: previousCode) { [weak self] running in
                DispatchQueue.main.async {
                    if running {
                        self?.performSegue(withIdentifier: "ShowGame", sender: previousCode)
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()
    }
    
    func findGame() {
//        findPlayerButton.isEnabled = false
        let difficulty = difficulties[picker.selectedRow(inComponent: 0)]
//        ChessAPI.findGame(difficulty: difficulty) { res in
//            DispatchQueue.main.async { [weak self] in
//                switch res {
//                case .success(let code):
//                    print(code)
//                    self?.join(code: code, difficulty: difficulty)
//                case .failure(let error):
//                    print(error)
//                }
//                self?.findPlayerButton.isEnabled = true
//            }
//        }
        performSegue(withIdentifier: "WaitingSegue", sender: difficulty)
    }

    func join(code: String, difficulty: ChessAPI.ServerGame.Difficulty?) {
        if let difficulty = difficulty {
            // Random person
            performSegue(withIdentifier: "WaitingSegue", sender: FoundGame(code: code, difficulty: difficulty))
        } else {
            // Join by code
            performSegue(withIdentifier: "WaitingSegue", sender: FoundGame(code: code, difficulty: nil))
        }
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if let vc = segue.destination as? WaitingViewController {
//            vc.difficulty = sender as? ChessAPI.ServerGame.Difficulty
//        } else if let vc = segue.destination as? GameViewController {
//            vc.isOnline = true
//            vc.onlineGameCode = sender as? String
//        }
    }
    
    struct FoundGame {
        var code: String
        var difficulty: ChessAPI.ServerGame.Difficulty?
    }
}

extension StartOnlineGameViewController: UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 3
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return difficulties[row].localized()
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !(textField.text ?? "").isEmpty {
            join(code: textField.text!, difficulty: nil)
        }
        return true
    }
}
