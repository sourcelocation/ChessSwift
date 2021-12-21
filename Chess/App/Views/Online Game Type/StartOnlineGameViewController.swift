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
    
    @IBAction func findButtonTapped(_ sender: UIButton) {
        if ChessAPI.login == nil {
            let alert = UIAlertController(title: "Please type in your username", message: nil, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.placeholder = "Username"
                textField.tintColor = #colorLiteral(red: 0.4086923003, green: 0.2684660256, blue: 0.1772648394, alpha: 1)
            }
            alert.view.tintColor = #colorLiteral(red: 0.4086923003, green: 0.2684660256, blue: 0.1772648394, alpha: 1)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Register", style: .default, handler: { _ in
                if let text = alert.textFields![0].text, !text.isEmpty {
                    ChessAPI.register(username: text, completion: { result in
                        DispatchQueue.main.async {
                            self.findGame()
                        }
                    })
                }
            }))
            present(alert, animated: true)
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
    }
    
    func findGame() {
        let difficulty = difficulties[picker.selectedRow(inComponent: 0)]
        ChessAPI.findGame(difficulty: difficulty) { res in
            switch res {
            case .success(let code):
                print(code)
                DispatchQueue.main.async {
                    self.join(code: code, difficulty: difficulty)
                }
            case .failure(let error):
                print(error)
            }
        }
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
        let foundGame = sender as! FoundGame
        let waitingVC = segue.destination as! WaitingViewController
        waitingVC.foundGame = foundGame
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
