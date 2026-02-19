//
//  SettingsView.swift
//  Chess
//
//  Created by exerhythm on 12/11/21.
//

import SwiftUI
import Combine

struct SettingsView: View {
    
    
    @State var chessClockSelected = false
    @State var showingProView = false
    
    @AppStorage("pro") var pro = false
        
    @AppStorage("chessClock") var chessClock = false
    @AppStorage("chessClockTime") var chessClockTime = 5
    
    @AppStorage("soundEnabled") var soundEnabled = true
    @AppStorage("flipBlackPieces") var flipBlackPieces = true
    @AppStorage("showLegalMoves") var showLegalMoves = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Game"), footer: pro ? nil : Text("Chess clock is available only in the Pro version.")) {
                    Toggle(isOn: $chessClockSelected) {
                        Text("Chess clock")
                    }
                    .onChange(of: chessClockSelected, perform: { value in
                        if pro {
                            chessClock = value
                        } else {
                            chessClockSelected = false
                            showingProView = true
                        }
                    })
                    
                    Picker("Time Limit", selection: $chessClockTime) {
                        ForEach([1,3,5,10,15,20,30,45,60,120], id: \.self) {
                            Text("\($0) minute\($0 != 1 ? "s" : "")")
                        }
                    }
                }
                Section(header: Text("Sounds")) {
                    Toggle(isOn: $soundEnabled) {
                        Text("Sounds")
                    }
                }
                Section(header: Text("Visuals")) {
                    Toggle(isOn: $flipBlackPieces) {
                        Text("Flip black pieces")
                    }
                    Toggle(isOn: $showLegalMoves) {
                        Text("Show legal moves")
                    }
                }
            }
            .navigationBarTitle(Text("Settings"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingProView) {
            PremiumView(showModal: $showingProView)
        }
        .onAppear {
            chessClockSelected = chessClock
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
