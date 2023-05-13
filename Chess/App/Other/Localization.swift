//
//  Localization.swift
//  Chess
//
//  Created by exerhythm on 12/29/21.
//

import UIKit

class LocalisableLabel: UILabel {
    
    @IBInspectable var localized: Bool = false {
        didSet {
            let key = text
            text = key?.localized
        }
    }

}
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

class LocalisableButton: UIButton {

    @IBInspectable var localized: Bool = false {
        didSet {
            guard let key = currentTitle else { return }
            UIView.performWithoutAnimation {
                setTitle(key.localized, for: .normal)
                layoutIfNeeded()
            }
        }
    }

}
