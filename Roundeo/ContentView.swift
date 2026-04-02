import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = VideoViewModel()
    @State private var isShowingFilePicker = false
    @State private var isDragTargeted = false
    @State private var isShowingHelp = false
    @Binding var showHelp: Bool

    var body: some View {
        ZStack {

            VideoPreviewView(
                viewModel: viewModel,
                isDragTargeted: isDragTargeted,
                onBrowse: { isShowingFilePicker = true }
            )
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
            ToolbarItem(placement: .primaryAction) {
                Button(action: { isShowingFilePicker = true }) {
                    Label("Load video", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button(action: { isShowingHelp = true }) {
                    Image(systemName: "questionmark.circle")
                }
                .help("Show help")
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
    ContentView(showHelp: .constant(false))
}
