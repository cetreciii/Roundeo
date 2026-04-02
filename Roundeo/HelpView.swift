import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("About Roundeo")
                        .font(DesignSystem.Typography.heading1.weight(.bold))
                    Text("Add rounded corners to your videos with optional device frames.")
                        .foregroundStyle(.secondary)
                }

                Divider()

                Section {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        helpStep("1. Load a video", "Drag and drop a video into the window, or click the + button to browse your files.")
                        helpStep("2. Adjust corners", "Use the presets (Subtle, Medium, Large, Pill) or drag the slider. The dark green circle lets you fine-tune corner radius visually.")
                        helpStep("3. Add a frame (optional)", "Click 'Add Frame' in the bottom bar to overlay a PNG device frame. Drag to position, use the light green corner handles to resize.")
                        helpStep("4. Export", "Click Export to save your video as a .mov file with transparent rounded corners.")
                    }
                } header: {
                    Text("How to use").font(DesignSystem.Typography.heading3)
                }

                Divider()

                Section {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(DesignSystem.Colors.accent)
                                Circle()
                                    .stroke(Color.white, lineWidth: 1.5)
                            }
                            .frame(width: 20, height: 20)

                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("Dark green circle")
                                    .font(DesignSystem.Typography.bodyEmphasis)
                                    .foregroundStyle(.white)
                                Text("Appears at the top of your video. Drag it left or right to adjust the corner radius in real-time.")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack(spacing: DesignSystem.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(DesignSystem.Colors.accentLight)
                                Circle()
                                    .stroke(Color.white, lineWidth: 1)
                            }
                            .frame(width: 16, height: 16)

                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("Light green circles")
                                    .font(DesignSystem.Typography.bodyEmphasis)
                                    .foregroundStyle(.white)
                                Text("Appear at the corners of your overlay frame. Drag them to resize the frame proportionally.")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Understanding the circles").font(DesignSystem.Typography.heading3)
                }

                Divider()

                Section {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        helpTip("Snap guides", "When dragging an overlay, green lines appear when it snaps to the video's horizontal or vertical center.")
                        helpTip("Resize with precision", "Click on a light green dot and resize your frame as you want, Roundeo can do it.")
                        helpTip("Transparency", "The checkerboard pattern shows where transparency will be in the exported video.")
                        helpTip("Video aspect ratios", "Roundeo handles videos of any size: vertical, horizontal, square, and everything in between.")
                    }
                } header: {
                    Text("Tips & tricks").font(DesignSystem.Typography.heading3)
                }

                Divider()

                Section {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Roundeo works with any video format that macOS supports (MP4, MOV, etc.). Exported videos are .mov files with HEVC video and alpha transparency for the rounded corners.")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Technical details").font(DesignSystem.Typography.heading3)
                }

                Spacer()
            }
            .padding(DesignSystem.Spacing.xl)
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
            .padding(DesignSystem.Spacing.md)
            .help("Close help")
        }
    }

    private func helpStep(_ title: String, _ description: String) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.bodyEmphasis)
                .foregroundStyle(.white)
            Text(description)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func helpTip(_ title: String, _ description: String) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.captionEmphasis)
                .foregroundStyle(DesignSystem.Colors.accent)
            Text(description)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HelpView()
}
