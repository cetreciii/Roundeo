import SwiftUI
import AVKit

struct VideoPreviewView: View {
    @ObservedObject var viewModel: VideoViewModel
    var isDragTargeted: Bool = false
    var onBrowse: () -> Void = {}

    var body: some View {
        if viewModel.player != nil {
            videoEditorView
        } else {
            DropZoneView(isDragTargeted: isDragTargeted, onBrowse: onBrowse)
        }
    }

    private var videoEditorView: some View {
        VStack(spacing: 0) {
            // Video canvas
            GeometryReader { geometry in
                let geo = VideoPreviewGeometry(
                    videoSize: viewModel.videoSize,
                    cropRect: activeCropRect,
                    canvasSize: geometry.size
                )

                ZStack {
                    // Dark canvas
                    DesignSystem.Colors.canvasBackground

                    // Checkerboard at video rect (shows through rounded corners)
                    CheckerboardView()
                        .frame(width: geo.displayFrame.width, height: geo.displayFrame.height)
                        .position(x: geo.displayFrame.midX, y: geo.displayFrame.midY)

                    // Video layer — clipped to crop region when crop is active
                    let (layerSize, layerOffset) = geo.layerSizeAndOffset()
                    let cropActive = activeCropRect != nil
                    let displayRadius = viewModel.cornerRadius * geo.scale
                    ZStack {
                        RoundedVideoLayerView(
                            player: viewModel.player!,
                            cornerRadius: cropActive ? 0 : viewModel.cornerRadius,
                            videoSize: viewModel.videoSize
                        )
                        .frame(width: layerSize.width, height: layerSize.height)
                        .offset(layerOffset)
                    }
                    .frame(width: geo.displayFrame.width, height: geo.displayFrame.height)
                    .clipShape(RoundedRectangle(cornerRadius: cropActive ? displayRadius : 0))
                    .position(x: geo.displayFrame.midX, y: geo.displayFrame.midY)

                    // PNG overlay
                    if viewModel.overlayImage != nil && !viewModel.isCropMode {
                        OverlayLayerView(
                            viewModel: viewModel,
                            videoFrame: geo.displayFrame,
                            scale: geo.scale
                        )
                    }

                    // Crop overlay
                    if viewModel.isCropMode {
                        CropOverlayView(
                            viewModel: viewModel,
                            videoFrame: geo.displayFrame,
                            scale: geo.scale
                        )
                    }

                    // Corner radius handle (hidden in crop mode)
                    if !viewModel.isCropMode {
                        handleOverlay(frame: geo.displayFrame, scale: geo.scale)
                    }
                }
            }

            // Player controls
            PlayerControlsView(viewModel: viewModel)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Bottom bar: presets + slider + frame + export
            BottomBarView(viewModel: viewModel)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(NSColor.windowBackgroundColor))
        }
    }

    @ViewBuilder
    private func handleOverlay(frame: CGRect, scale: CGFloat) -> some View {
        let handleSize: CGFloat = 20
        let handlePos = CGPoint(
            x: frame.minX + viewModel.cornerRadius * scale,
            y: frame.minY + 20
        )

        ZStack {
            Circle()
                .fill(DesignSystem.Colors.accent)
            Circle()
                .stroke(Color.black, lineWidth: 1.5)
        }
        .frame(width: handleSize, height: handleSize)
        .shadow(color: .black.opacity(0.4), radius: 3)
        .position(handlePos)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard scale > 0 else { return }
                        let delta = value.location.x - frame.minX
                        viewModel.cornerRadius = max(0, min(viewModel.maxRadius, delta / scale))
                    }
            )
    }

    private var activeCropRect: CGRect? {
        viewModel.isCropMode ? nil : viewModel.cropRect
    }
}
