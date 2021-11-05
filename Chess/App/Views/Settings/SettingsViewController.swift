//
//  SettingsViewController.swift
//  Chess
//
//  Created by exerhythm on 7/8/21.
//

import UIKit

class SettingsViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    var vc: GameViewController!
    
    @IBOutlet weak var soundsSwitch: UISwitch!
    @IBOutlet weak var checkSoundSwitch: UISwitch!
    @IBOutlet weak var showHintsSwitch: UISwitch!
    @IBOutlet weak var noRulesSwitch: UISwitch!
    @IBOutlet weak var autoClockSwitch: UISwitch!
    
    @IBOutlet weak var clockSwitch: UISwitch!
    @IBOutlet weak var clockTimePickerView: UIPickerView!
    @IBOutlet weak var clockTimeLabel: UILabel!
    
    
    var clockTimeValues:[Int] = [1,5,10,15,20,30,45]
    var clockTimePickerHidden = true
    
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func soundsSwitch(_ sender: UISwitch) {
        UserDefaults.standard.setValue(!sender.isOn, forKey: "noSounds")
        
        checkSoundSwitch.isEnabled = sender.isOn
        if sender.isOn {
            checkSoundSwitch.setOn(!UserDefaults.standard.bool(forKey: "noCheckSound"), animated: true)
        } else {
            checkSoundSwitch.setOn(false, animated: true)
        }
    }
    @IBAction func clockSwitch(_ sender: UISwitch) {
        if isInPortrait, sender.isOn {
            let alert = UIAlertController(title: "Please rotate your device", message: "Clock can only work in Landscape device orientation", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                sender.setOn(false, animated: true)
            }))
            present(alert, animated: true)
            return
        }
        if UserDefaults.standard.integer(forKey: "clockSelectedMinutes") == 0 {
            UserDefaults.standard.setValue(5, forKey: "clockSelectedMinutes")
        }
        if vc.clockWhite < 1 || vc.clockBlack < 1 {
            vc.resetClockValues()
        }
        UserDefaults.standard.setValue(sender.isOn, forKey: "clockEnabled")
        vc.toggleClock(on: sender.isOn)
        
        if !sender.isOn {
            clockTimePickerHidden = true
        }
        
        noRulesSwitch.isEnabled = !sender.isOn
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    @IBAction func noRulesSwitch(_ sender: UISwitch) {
        UserDefaults.standard.setValue(sender.isOn, forKey: "noRules")
        vc.toggleEditor(on: sender.isOn)
        vc.board?.restart()
        vc.board?.saveGame()
        
        clockSwitch.isEnabled = !sender.isOn
    }
    
    @IBAction func checkSoundSwitch(_ sender: UISwitch) {
        UserDefaults.standard.setValue(!sender.isOn, forKey: "noCheckSound")
    }
    
    @IBAction func showMovesSwitch(_ sender: UISwitch) {
        UserDefaults.standard.setValue(!sender.isOn, forKey: "showHints")
    }
    @IBAction func autoClockSwitch(_ sender: UISwitch) {
        UserDefaults.standard.setValue(sender.isOn, forKey: "autoClock")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        noRulesSwitch.isOn = UserDefaults.standard.bool(forKey: "noRules")
        soundsSwitch.isOn = !UserDefaults.standard.bool(forKey: "noSounds")
        checkSoundSwitch.isEnabled = soundsSwitch.isOn
        checkSoundSwitch.isOn = soundsSwitch.isOn ? !UserDefaults.standard.bool(forKey: "noCheckSound") : false
        showHintsSwitch.isOn = !UserDefaults.standard.bool(forKey: "showHints")
        
        // MARK: Pro Version
        clockSwitch.isOn = UserDefaults.standard.bool(forKey: "clockEnabled")
        clockSwitch.isEnabled = vc.board!.proVersion && !UserDefaults.standard.bool(forKey: "noRules")
        noRulesSwitch.isEnabled = vc.board!.proVersion && !clockSwitch.isOn
        noRulesSwitch.isOn = UserDefaults.standard.bool(forKey: "noRules")
        autoClockSwitch.isOn = UserDefaults.standard.bool(forKey: "autoClock")
        
        clockTimePickerView.delegate = self
        clockTimePickerView.dataSource = self
        
        clockTimeLabel.text = "\(UserDefaults.standard.integer(forKey: "clockSelectedMinutes") == 0 ? 5 : UserDefaults.standard.integer(forKey: "clockSelectedMinutes")):00"
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0, indexPath.row == 2 {
            if clockTimePickerHidden || !clockSwitch.isOn {
                clockTimePickerView.isHidden = true
                return 0
            } else {
                clockTimePickerView.isHidden = false
                return 128
            }
        }
        if indexPath.section == 0 && (indexPath.row == 1 || indexPath.row == 3) {
            return clockSwitch.isOn ? tableView.estimatedRowHeight : 0
        }
        return tableView.estimatedRowHeight
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0, indexPath.row == 1 {
            tableView.deselectRow(at: indexPath, animated: true)
            clockTimePickerHidden.toggle()
            clockTimePickerView.selectRow((clockTimeValues.firstIndex(of: UserDefaults.standard.integer(forKey: "clockSelectedMinutes")) ?? 1), inComponent: 0, animated: false)
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        clockTimeLabel.text = "\(clockTimeValues[row]):00"
        UserDefaults.standard.setValue(clockTimeValues[row], forKey: "clockSelectedMinutes")
        vc.resetClockValues()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(clockTimeValues[row]):00"
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return clockTimeValues.count
    }
}

var isInPortrait: Bool {
    if #available(iOS 13.0, *) {
        return UIApplication.shared.windows[0].windowScene!.interfaceOrientation.isPortrait
    } else {
        return UIApplication.shared.statusBarOrientation.isPortrait
    }
}
