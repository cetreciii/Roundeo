//
//  RoundeoApp.swift
//  Roundeo
//
//  Created by Igor Tarantino on 26/03/26.
//

import SwiftUI

@main
struct RoundeoApp: App {
    @State private var showHelp = false

    var body: some Scene {
        WindowGroup {
            ContentView(showHelp: $showHelp)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .help) {
                Button("Roundeo Help") {
                    showHelp = true
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
        }
    }
}
