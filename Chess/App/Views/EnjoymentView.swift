//
//  TacoDialogView.swift
//  Demo
//
//  Created by Tim Moose on 8/12/16.
//  Copyright © 2016 SwiftKick Mobile. All rights reserved.
//

import UIKit
import SwiftMessages

class EnjoymentView: MessageView {
    
    var noAction: (() -> Void)?
    var yesAction: (() -> Void)?
    
    @IBAction func yesTapped() {
        yesAction?()
    }

    @IBAction func notReallyTapped() {
        noAction?()
    }
    
}
