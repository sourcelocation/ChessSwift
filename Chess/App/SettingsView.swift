//
//  SettingsView.swift
//  Chess
//
//  Created by exerhythm on 12/11/21.
//

import SwiftUI
import Combine

struct SettingsView: View {
    @AppStorage("soundEnabled") var soundEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sounds")) {
                    Toggle(isOn: $soundEnabled) {
                        Text("Sounds")
                    }
                }
            }
            .navigationBarTitle(Text("Settings"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
