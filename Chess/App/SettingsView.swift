import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppEnvironment.shared.settings
    @State private var chessClockSelected = false
    @State private var showingProView = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Game"), footer: settings.proEnabled ? nil : Text("Chess clock is available only in the Pro version.")) {
                    Toggle(isOn: $chessClockSelected) {
                        settingsRowLabel("Chess clock", systemImage: "clock")
                    }
                    .onChange(of: chessClockSelected) { value in
                        if settings.proEnabled {
                            settings.chessClockEnabled = value
                        } else {
                            chessClockSelected = false
                            showingProView = true
                        }
                    }

                    Picker(selection: $settings.chessClockMinutes) {
                        ForEach([1,3,5,10,15,20,30,45,60,120], id: \.self) {
                            Text("\($0) minute\($0 != 1 ? "s" : "")")
                        }
                    } label: {
                        settingsRowLabel("Time Limit", systemImage: "timer")
                    }
                }

                Section(header: Text("Sounds")) {
                    Toggle(isOn: $settings.soundEnabled) {
                        settingsRowLabel("Sounds", systemImage: "speaker.wave.2")
                    }
                    Toggle(isOn: $settings.checkSoundEnabled) {
                        settingsRowLabel("Check sound", systemImage: "waveform")
                    }
                    .disabled(!settings.soundEnabled)
                }

                Section(header: Text("Visuals")) {
                    Toggle(isOn: $settings.flipBlackPieces) {
                        settingsRowLabel("Flip black pieces", systemImage: "arrow.up.and.down")
                    }
                    Toggle(isOn: $settings.showLegalMoves) {
                        settingsRowLabel("Show legal moves", systemImage: "scope")
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
            chessClockSelected = settings.chessClockEnabled
        }
    }

    private func settingsRowLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.primary.opacity(0.12))
                .frame(width: 24, height: 24)
                .overlay {
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .semibold))
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(.primary)
                }
            Text(title)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
