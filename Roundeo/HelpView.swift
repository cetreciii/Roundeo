import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About Roundeo")
                        .font(.title2.weight(.bold))
                    Text("Add rounded corners to your videos with optional device frames.")
                        .foregroundStyle(.secondary)
                }

                Divider()

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        helpStep("1. Load a video", "Drag and drop a video into the window, or click the + button to browse your files.")
                        helpStep("2. Adjust corners", "Use the presets (Subtle, Medium, Large, Pill) or drag the slider. The yellow handle lets you fine-tune visually.")
                        helpStep("3. Add a frame (optional)", "Click 'Add Frame' in the bottom bar to overlay a PNG device frame. Drag to position, use the blue corner handles to resize.")
                        helpStep("4. Export", "Click Export to save your video as a .mov file with transparent rounded corners.")
                    }
                } header: {
                    Text("How to use").font(.headline)
                }

                Divider()

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        helpTip("Snap guides", "When dragging an overlay, blue lines appear when it snaps to the video's horizontal or vertical center.")
                        helpTip("Resize with precision", "Click on a blue dot and resize your frame as you want, Roundeo can do it.")
                        helpTip("Transparency", "The checkerboard pattern shows where transparency will be in the exported video.")
                        helpTip("Video aspect ratios", "Roundeo handles videos of any size: vertical, horizontal, square, and everything in between.")
                    }
                } header: {
                    Text("Tips & tricks").font(.headline)
                }

                Divider()

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Roundeo works with any video format that macOS supports (MP4, MOV, etc.). Exported videos are .mov files with HEVC video and alpha transparency for the rounded corners.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Technical details").font(.headline)
                }

                Spacer()
            }
            .padding(20)
        }
        .frame(minWidth: 400, minHeight: 500)
        .navigationTitle("Help")
        .keyboardShortcut(.cancelAction)
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(12)
            .help("Close help")
        }
    }

    private func helpStep(_ title: String, _ description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func helpTip(_ title: String, _ description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HelpView()
}
