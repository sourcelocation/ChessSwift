//
//  SettingsView.swift
//  Chess
//
//  Created by exerhythm on 12/11/21.
//

import SwiftUI
import Combine

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sounds")) {
                    Toggle(isOn: $settings.soundsEnabled) {
                        Text("Sounds")
                    }
                }
                
                Section(header: Text("Sleep tracking settings")) {
                }
            }
            .navigationBarTitle(Text("Settings"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

final class SettingsStore: ObservableObject {
    private enum Keys {
        static let pro = "pro"
        static let soundsEnabled = "sounds_enabled"
    }
    
    private let cancellable: Cancellable
    private let defaults: UserDefaults
    
    let objectWillChange = PassthroughSubject<Void, Never>()
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        
        defaults.register(defaults: [
            Keys.pro: false,
            Keys.soundsEnabled: true,
        ])
        
        cancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .map { _ in () }
            .subscribe(objectWillChange)
    }
    
    var isPro: Bool {
        set { defaults.set(newValue, forKey: Keys.pro) }
        get { defaults.bool(forKey: Keys.pro) }
    }
    
    var soundsEnabled: Bool {
        set { defaults.set(newValue, forKey: Keys.soundsEnabled) }
        get { defaults.bool(forKey: Keys.soundsEnabled) }
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
