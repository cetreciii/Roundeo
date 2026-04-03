import SwiftUI

// MARK: - Player controls

struct PlayerControlsView: View {
    @ObservedObject var viewModel: VideoViewModel

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Button(action: { viewModel.togglePlayPause() }) {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.body)
                    .frame(width: DesignSystem.Sizing.iconStandard)
            }
            .buttonStyle(.plain)

            Text(formatTime(viewModel.currentTime))
                .font(DesignSystem.Typography.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)

            Slider(
                value: Binding(
                    get: { viewModel.currentTime },
                    set: { viewModel.currentTime = $0; viewModel.seek(to: $0) }
                ),
                in: 0...max(viewModel.duration, 0.01)
            ) { editing in
                viewModel.isSeeking = editing
            }
            .tint(DesignSystem.Colors.accent)

            Text(formatTime(viewModel.duration))
                .font(DesignSystem.Typography.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Bottom bar

struct BottomBarView: View {
    @ObservedObject var viewModel: VideoViewModel

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Export dimensions
            HStack(spacing: DesignSystem.Spacing.xs) {
                Text("Size")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
                TextField("W", text: $viewModel.exportWidthText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 56)
                    .multilineTextAlignment(.trailing)
                Text("×")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
                TextField("H", text: $viewModel.exportHeightText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 56)
                Text("px")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.tertiary)
            }

            Divider()
                .frame(height: 20)

            // Slider + value
            Slider(value: $viewModel.cornerRadius, in: 0...viewModel.maxRadius)
                .frame(minWidth: 120)
                .tint(DesignSystem.Colors.accent)

            TextField("", value: $viewModel.cornerRadius, format: .number.precision(.fractionLength(0)))
                .textFieldStyle(.roundedBorder)
                .frame(width: 52)
                .multilineTextAlignment(.trailing)

            Text("px")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.tertiary)

            Divider()
                .frame(height: 20)

            // Crop button
            if viewModel.isCropMode {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Button("Apply") {
                        viewModel.isCropMode = false
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    Button("Reset") {
                        viewModel.cropRect = nil
                        viewModel.isCropMode = false
                    }
                    .controlSize(.small)
                }
            } else {
                Button(action: { viewModel.isCropMode = true }) {
                    Label(viewModel.cropRect != nil ? "Crop ✓" : "Crop", systemImage: "crop")
                }
                .controlSize(.small)
                .disabled(viewModel.url == nil)
            }

            Divider()
                .frame(height: 20)

            // Frame overlay button
            if viewModel.overlayImage != nil {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "iphone")
                        .font(DesignSystem.Typography.caption)
                    Text(viewModel.overlayURL?.deletingPathExtension().lastPathComponent ?? "Frame")
                        .font(DesignSystem.Typography.caption)
                        .lineLimit(1)
                        .frame(maxWidth: 80)
                    Button(action: { viewModel.removeOverlay() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(DesignSystem.Typography.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(Capsule().fill(Color.white.opacity(0.08)))
            } else {
                Button(action: { viewModel.pickOverlay() }) {
                    Label("Add Frame", systemImage: "iphone")
                }
                .controlSize(.small)
                .disabled(viewModel.url == nil)
            }

            Divider()
                .frame(height: 20)

            // Export button
            Button(action: { viewModel.exportVideo() }) {
                if viewModel.isExporting {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        ProgressView()
                            .controlSize(.small)
                        Text("\(Int(viewModel.exportProgress * 100))%")
                            .monospacedDigit()
                    }
                    .frame(width: 80)
                } else {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .frame(width: 80)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.url == nil || viewModel.isExporting)
        }
    }
}
