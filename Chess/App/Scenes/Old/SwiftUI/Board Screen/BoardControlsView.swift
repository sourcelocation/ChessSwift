//
//  BoardControlsView.swift
//  Chess
//
//  Created by exerhythm on 12/12/21.
//

import SwiftUI

struct BoardControlsView: View {
    @Binding var showingSettings: Bool
    
    var squareControls: Bool
    var undo: () -> Void
    var restart: () -> Void
    var showProView: () -> Void
    var showSettingsView: () -> Void
    
    var body: some View {
        
        let undo = Button(action: {
            self.undo()
        }, label: {
            Image(systemName: "arrow.left")
                .font(.system(size: 24, weight: .medium))
        })
        let restart =
        Button(action: {
            self.restart()
        }, label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 24, weight: .medium))
        })
        let pro =
        Button(action: {
            showProView()
        }, label: {
            Image(systemName: "crown")
                .font(.system(size: 24, weight: .medium))
        })
        
        let settings =
        Button(action: {
            self.showSettingsView()
        }, label: {
            Image(systemName: "gearshape")
                .font(.system(size: 24, weight: .medium))
        })
            .popover(isPresented: $showingSettings) {
                SettingsView()
                    .frame(width: 375, height: 500)
            }
        if squareControls {
            VStack(alignment: .center) {
                HStack(alignment: .center) {
                    undo
                    Spacer()
                    restart
                }
                
                Spacer()
                HStack(alignment: .center) {
                    pro
                    Spacer()
                    settings
                }
            }
            .frame(maxWidth: 85, maxHeight:85)
        } else {
            HStack {
                undo
                restart
                pro
                settings
            }
        }
    }
}

struct BoardControlsView_Previews: PreviewProvider {
    static var previews: some View {
        BoardControlsView(showingSettings: .constant(false), squareControls: true, undo: {}, restart: {}, showProView: {}, showSettingsView: {})
    }
}
