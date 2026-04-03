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
    @State private var showRatingAlert = false

    var body: some Scene {
        WindowGroup {
            ContentView(showHelp: $showHelp, showRatingAlert: $showRatingAlert)
                .frame(minWidth: 1000, minHeight: 700)
                .onAppear {
                    checkAndShowRatingPrompt()
                }
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

    private func checkAndShowRatingPrompt() {
        let isDisabled = UserDefaults.standard.bool(forKey: "ratingPromptDisabled")
        guard !isDisabled else { return }

        let launchCount = UserDefaults.standard.integer(forKey: "appLaunchCount")
        let newLaunchCount = launchCount + 1
        UserDefaults.standard.set(newLaunchCount, forKey: "appLaunchCount")

        print("[Roundeo] App launch count: \(newLaunchCount)")

        if newLaunchCount == 4 {
            showRatingAlert = true
            print("[Roundeo] Showing rating prompt (4th launch)")
        }
    }
}
