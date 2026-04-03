import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = VideoViewModel()
    @State private var isShowingFilePicker = false
    @State private var isDragTargeted = false
    @State private var isShowingHelp = false
    @Binding var showHelp: Bool
    @Binding var showRatingAlert: Bool

    var body: some View {
        ZStack {

            VideoPreviewView(
                viewModel: viewModel,
                isDragTargeted: isDragTargeted,
                onBrowse: { isShowingFilePicker = true }
            )
            .accentColor(DesignSystem.Colors.accent)
            .onDrop(of: [.movie, .quickTimeMovie, .mpeg4Movie], isTargeted: $isDragTargeted) { providers in
                loadVideoFromDrop(providers: providers)
                return true
            }

            if viewModel.showOnboarding {
                OnboardingView(showOnboarding: $viewModel.showOnboarding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: { isShowingHelp = true }) {
                    Image(systemName: "questionmark.circle")
                }
                .help("Show help")
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: { isShowingFilePicker = true }) {
                    Text(viewModel.player == nil ? "Add video" : "Change video")
                }
            }
        }
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.movie, .quickTimeMovie, .mpeg4Movie],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    if url.startAccessingSecurityScopedResource() {
                        viewModel.loadVideo(url: url)
                    } else {
                        viewModel.loadVideo(url: url)
                    }
                }
            case .failure(let error):
                print("Error picking file: \(error.localizedDescription)")
            }
        }
        .alert("Export result", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
        .navigationTitle("Roundeo")
        .disabled(viewModel.showOnboarding)
        .sheet(isPresented: Binding(
            get: { isShowingHelp || showHelp },
            set: { newValue in
                isShowingHelp = newValue
                showHelp = newValue
            }
        )) {
            HelpView()
        }
        .background(
            Button("") {
                isShowingHelp = true
            }
            .keyboardShortcut("?", modifiers: [.command])
            .hidden()
        )
        .accentColor(DesignSystem.Colors.accent)
        .alert("Enjoying Roundeo?", isPresented: $showRatingAlert) {
            Button("Rate on App Store") {
                if let url = URL(string: "macappstore://apps.apple.com/app/roundeo") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Remind me later", role: .cancel) { }
            Button("Don't ask again", role: .destructive) {
                UserDefaults.standard.set(true, forKey: "ratingPromptDisabled")
            }
        } message: {
            Text("If you're enjoying Roundeo, would you mind leaving a rating on the App Store? It helps me improve!")
        }
    }

    private func loadVideoFromDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
            guard let url = url else { return }
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: tempURL)
            do {
                try FileManager.default.copyItem(at: url, to: tempURL)
                DispatchQueue.main.async {
                    self.viewModel.loadVideo(url: tempURL)
                }
            } catch {
                print("Error copying dropped video: \(error)")
            }
        }
    }
}

#Preview {
    ContentView(showHelp: .constant(false), showRatingAlert: .constant(false))
}
