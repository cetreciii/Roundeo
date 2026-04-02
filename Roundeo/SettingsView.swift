import SwiftUI

struct SettingsView: View {
    @State private var didReset = false

    var body: some View {
        Form {
            Section("Onboarding") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show onboarding on next launch")
                        Text("The welcome guide will appear again when you reopen the app.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(didReset ? "Done" : "Reset") {
                        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
                        didReset = true
                    }
                    .disabled(didReset)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .padding()
    }
}

#Preview {
    SettingsView()
}
