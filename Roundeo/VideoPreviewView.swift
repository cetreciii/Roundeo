import SwiftUI
import AVKit

// MARK: - Checkerboard (transparency indicator)

private struct CheckerboardView: View {
    let squareSize: CGFloat = 8

    var body: some View {
        Canvas { context, size in
            let cols = Int(ceil(size.width / squareSize))
            let rows = Int(ceil(size.height / squareSize))

            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(white: 0.25)))

            for row in 0..<rows {
                for col in 0..<cols where (row + col) % 2 == 0 {
                    let rect = CGRect(
                        x: CGFloat(col) * squareSize,
                        y: CGFloat(row) * squareSize,
                        width: squareSize,
                        height: squareSize
                    )
                    context.fill(Path(rect), with: .color(Color(white: 0.18)))
                }
            }
        }
    }
}

// MARK: - AVPlayerLayer view

struct RoundedVideoLayerView: NSViewRepresentable {
    let player: AVPlayer
    let cornerRadius: CGFloat
    let videoSize: CGSize

    func makeNSView(context: Context) -> VideoHostView {
        let view = VideoHostView()
        view.configure(player: player, videoSize: videoSize, cornerRadius: cornerRadius)
        return view
    }

    func updateNSView(_ view: VideoHostView, context: Context) {
        view.update(player: player, videoSize: videoSize, cornerRadius: cornerRadius)
    }

    class VideoHostView: NSView {
        private var playerLayer: AVPlayerLayer?
        private var currentVideoSize: CGSize = .zero
        private var currentCornerRadius: CGFloat = 0

        func configure(player: AVPlayer, videoSize: CGSize, cornerRadius: CGFloat) {
            wantsLayer = true
            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resize
            self.layer?.addSublayer(layer)
            self.playerLayer = layer
            self.currentVideoSize = videoSize
            self.currentCornerRadius = cornerRadius
        }

        func update(player: AVPlayer, videoSize: CGSize, cornerRadius: CGFloat) {
            playerLayer?.player = player
            currentVideoSize = videoSize
            currentCornerRadius = cornerRadius
            layoutPlayerLayer()
        }

        override func layout() {
            super.layout()
            layoutPlayerLayer()
        }

        private func layoutPlayerLayer() {
            guard let playerLayer = playerLayer,
                  currentVideoSize.width > 0, bounds.width > 0 else { return }

            // The NSView is already sized to the exact video display frame by SwiftUI,
            // so the player layer just fills bounds. Scale cornerRadius proportionally.
            let ratio = bounds.width / currentVideoSize.width

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            playerLayer.frame = bounds
            playerLayer.cornerRadius = currentCornerRadius * ratio
            playerLayer.masksToBounds = true
            CATransaction.commit()
        }
    }
}

// MARK: - Empty state / drop zone

private struct DropZoneView: View {
    let isDragTargeted: Bool
    let onBrowse: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.roundcorners.fill")
                .font(.system(size: 56))
                .foregroundStyle(isDragTargeted ? .white : .secondary)

            Text("Drop a video here")
                .font(.title2.weight(.medium))
                .foregroundStyle(isDragTargeted ? .white : .secondary)

            Text("or")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Button("Browse Files", action: onBrowse)
                .buttonStyle(.bordered)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .foregroundStyle(isDragTargeted ? Color.accentColor : Color.white.opacity(0.15))
                .padding(20)
        }
        .background(Color(white: 0.12))
        .animation(.easeInOut(duration: 0.15), value: isDragTargeted)
    }
}

// MARK: - Player controls

private struct PlayerControlsView: View {
    @ObservedObject var viewModel: VideoViewModel

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { viewModel.togglePlayPause() }) {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.body)
                    .frame(width: 20)
            }
            .buttonStyle(.plain)

            Text(formatTime(viewModel.currentTime))
                .font(.caption.monospacedDigit())
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

            Text(formatTime(viewModel.duration))
                .font(.caption.monospacedDigit())
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

// MARK: - Radius presets

private struct RadiusPreset {
    let name: String
    let fraction: Double
}

private let presets = [
    RadiusPreset(name: "Subtle", fraction: 0.06),
    RadiusPreset(name: "Medium", fraction: 0.15),
    RadiusPreset(name: "Large", fraction: 0.30),
    RadiusPreset(name: "Pill", fraction: 1.0),
]

// MARK: - Bottom bar

private struct BottomBarView: View {
    @ObservedObject var viewModel: VideoViewModel

    var body: some View {
        HStack(spacing: 16) {
            // Presets
            HStack(spacing: 6) {
                ForEach(presets, id: \.name) { preset in
                    let target = preset.fraction * viewModel.maxRadius
                    let isActive = abs(viewModel.cornerRadius - target) < 1

                    Button(preset.name) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.cornerRadius = target
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.caption.weight(isActive ? .bold : .regular))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(isActive ? Color.accentColor : Color.white.opacity(0.08))
                    )
                    .foregroundStyle(isActive ? .white : .secondary)
                }
            }

            Divider()
                .frame(height: 20)

            // Slider + value
            Slider(value: $viewModel.cornerRadius, in: 0...viewModel.maxRadius)
                .frame(minWidth: 120)

            TextField("", value: $viewModel.cornerRadius, format: .number.precision(.fractionLength(0)))
                .textFieldStyle(.roundedBorder)
                .frame(width: 52)
                .multilineTextAlignment(.trailing)

            Text("px")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Divider()
                .frame(height: 20)

            // Crop button
            if viewModel.isCropMode {
                HStack(spacing: 6) {
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
                HStack(spacing: 6) {
                    Image(systemName: "iphone")
                        .font(.caption)
                    Text(viewModel.overlayURL?.deletingPathExtension().lastPathComponent ?? "Frame")
                        .font(.caption)
                        .lineLimit(1)
                        .frame(maxWidth: 80)
                    Button(action: { viewModel.removeOverlay() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
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
                    HStack(spacing: 6) {
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

// MARK: - Overlay with drag + snap

private struct OverlayLayerView: View {
    @ObservedObject var viewModel: VideoViewModel
    let videoFrame: CGRect
    let scale: CGFloat

    @State private var dragStartOffset: CGSize = .zero
    @State private var dragStartScale: CGFloat = 1.0
    @State private var isDragging = false

    private let snapThreshold: CGFloat = 8 // display points
    private let handleSize: CGFloat = 10

    private var isSnappedH: Bool {
        guard scale > 0 else { return false }
        return abs(viewModel.overlayOffset.width) < snapThreshold / scale
    }

    private var isSnappedV: Bool {
        guard scale > 0 else { return false }
        return abs(viewModel.overlayOffset.height) < snapThreshold / scale
    }

    var body: some View {
        let fitted = viewModel.overlayFittedSize
        let displayW = fitted.width * scale * viewModel.overlayScale
        let displayH = fitted.height * scale * viewModel.overlayScale
        let centerX = videoFrame.midX + viewModel.overlayOffset.width * scale
        let centerY = videoFrame.midY + viewModel.overlayOffset.height * scale

        ZStack {
            // Snap guide lines
            if isDragging {
                if isSnappedH {
                    Path { p in
                        p.move(to: CGPoint(x: videoFrame.midX, y: videoFrame.minY))
                        p.addLine(to: CGPoint(x: videoFrame.midX, y: videoFrame.maxY))
                    }
                    .stroke(Color.accentColor, lineWidth: 1)
                }
                if isSnappedV {
                    Path { p in
                        p.move(to: CGPoint(x: videoFrame.minX, y: videoFrame.midY))
                        p.addLine(to: CGPoint(x: videoFrame.maxX, y: videoFrame.midY))
                    }
                    .stroke(Color.accentColor, lineWidth: 1)
                }
            }

            // Overlay image
            if let nsImage = viewModel.overlayImage {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: displayW, height: displayH)
                    .position(x: centerX, y: centerY)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                guard scale > 0 else { return }
                                let thresh = snapThreshold / scale

                                var newW = dragStartOffset.width + value.translation.width / scale
                                var newH = dragStartOffset.height + value.translation.height / scale

                                if abs(newW) < thresh { newW = 0 }
                                if abs(newH) < thresh { newH = 0 }

                                viewModel.overlayOffset = CGSize(width: newW, height: newH)
                            }
                            .onEnded { _ in
                                isDragging = false
                                dragStartOffset = viewModel.overlayOffset
                            }
                    )

                // Resize handles (corners)
                ForEach([0, 1, 2, 3], id: \.self) { corner in
                    ResizeHandle(
                        position: handlePosition(corner, center: CGPoint(x: centerX, y: centerY), size: CGSize(width: displayW, height: displayH)),
                        overlayCenter: CGPoint(x: centerX, y: centerY),
                        viewModel: viewModel,
                        dragStartScale: $dragStartScale
                    )
                }
            }
        }
        .onChange(of: viewModel.overlayImage == nil) { _, isNil in
            if isNil {
                dragStartOffset = .zero
                dragStartScale = 1.0
            }
        }
    }

    private func handlePosition(_ corner: Int, center: CGPoint, size: CGSize) -> CGPoint {
        let halfW = size.width / 2
        let halfH = size.height / 2
        switch corner {
        case 0: return CGPoint(x: center.x - halfW, y: center.y - halfH) // top-left
        case 1: return CGPoint(x: center.x + halfW, y: center.y - halfH) // top-right
        case 2: return CGPoint(x: center.x - halfW, y: center.y + halfH) // bottom-left
        default: return CGPoint(x: center.x + halfW, y: center.y + halfH) // bottom-right
        }
    }
}

private struct ResizeHandle: View {
    let position: CGPoint
    let overlayCenter: CGPoint
    @ObservedObject var viewModel: VideoViewModel
    @Binding var dragStartScale: CGFloat

    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 10, height: 10)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let startDist = hypot(
                            value.startLocation.x - overlayCenter.x,
                            value.startLocation.y - overlayCenter.y
                        )
                        guard startDist > 0 else { return }
                        let currentDist = hypot(
                            value.location.x - overlayCenter.x,
                            value.location.y - overlayCenter.y
                        )
                        viewModel.overlayScale = max(0.1, dragStartScale * (currentDist / startDist))
                    }
                    .onEnded { _ in
                        dragStartScale = viewModel.overlayScale
                    }
            )
    }
}

// MARK: - Crop overlay

private struct CropOverlayView: View {
    @ObservedObject var viewModel: VideoViewModel
    let videoFrame: CGRect
    let scale: CGFloat

    @State private var dragStartRect: CGRect = .zero

    private var displayRect: CGRect {
        guard let crop = viewModel.cropRect else { return videoFrame }
        return CGRect(
            x: videoFrame.minX + crop.minX * scale,
            y: videoFrame.minY + crop.minY * scale,
            width: crop.width * scale,
            height: crop.height * scale
        )
    }

    var body: some View {
        let dr = displayRect
        ZStack {
            // Dimmed regions outside crop
            dimRect(CGRect(x: videoFrame.minX, y: videoFrame.minY, width: videoFrame.width, height: dr.minY - videoFrame.minY))
            dimRect(CGRect(x: videoFrame.minX, y: dr.maxY, width: videoFrame.width, height: videoFrame.maxY - dr.maxY))
            dimRect(CGRect(x: videoFrame.minX, y: dr.minY, width: dr.minX - videoFrame.minX, height: dr.height))
            dimRect(CGRect(x: dr.maxX, y: dr.minY, width: videoFrame.maxX - dr.maxX, height: dr.height))

            // Crop border
            Rectangle()
                .strokeBorder(Color.white, lineWidth: 1.5)
                .frame(width: dr.width, height: dr.height)
                .position(x: dr.midX, y: dr.midY)
                .gesture(DragGesture()
                    .onChanged { value in
                        guard scale > 0 else { return }
                        let dx = value.translation.width / scale
                        let dy = value.translation.height / scale
                        let w = dragStartRect.width, h = dragStartRect.height
                        let vs = viewModel.videoSize
                        let newX = max(0, min(vs.width - w, dragStartRect.minX + dx))
                        let newY = max(0, min(vs.height - h, dragStartRect.minY + dy))
                        viewModel.cropRect = CGRect(x: newX, y: newY, width: w, height: h)
                    }
                    .onEnded { _ in dragStartRect = viewModel.cropRect ?? CGRect(origin: .zero, size: viewModel.videoSize) }
                )

            // Corner handles
            ForEach(0..<4, id: \.self) { i in
                CropCornerHandle(corner: i, displayRect: dr, scale: scale, viewModel: viewModel, dragStartRect: $dragStartRect)
            }
        }
        .onAppear {
            if viewModel.cropRect == nil {
                viewModel.cropRect = CGRect(origin: .zero, size: viewModel.videoSize)
            }
            dragStartRect = viewModel.cropRect ?? CGRect(origin: .zero, size: viewModel.videoSize)
        }
    }

    @ViewBuilder
    private func dimRect(_ rect: CGRect) -> some View {
        if rect.width > 0 && rect.height > 0 {
            Rectangle()
                .fill(Color.black.opacity(0.5))
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
        }
    }
}

private struct CropCornerHandle: View {
    let corner: Int
    let displayRect: CGRect
    let scale: CGFloat
    @ObservedObject var viewModel: VideoViewModel
    @Binding var dragStartRect: CGRect

    private var position: CGPoint {
        switch corner {
        case 0: return CGPoint(x: displayRect.minX, y: displayRect.minY)
        case 1: return CGPoint(x: displayRect.maxX, y: displayRect.minY)
        case 2: return CGPoint(x: displayRect.minX, y: displayRect.maxY)
        default: return CGPoint(x: displayRect.maxX, y: displayRect.maxY)
        }
    }

    var body: some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 12, height: 12)
            .position(position)
            .gesture(DragGesture()
                .onChanged { value in
                    guard scale > 0 else { return }
                    let dx = value.translation.width / scale
                    let dy = value.translation.height / scale
                    let vs = viewModel.videoSize
                    let minSize: CGFloat = 20
                    var x0 = dragStartRect.minX, y0 = dragStartRect.minY
                    var x1 = dragStartRect.maxX, y1 = dragStartRect.maxY
                    switch corner {
                    case 0: x0 = max(0, min(x1 - minSize, x0 + dx)); y0 = max(0, min(y1 - minSize, y0 + dy))
                    case 1: x1 = min(vs.width, max(x0 + minSize, x1 + dx)); y0 = max(0, min(y1 - minSize, y0 + dy))
                    case 2: x0 = max(0, min(x1 - minSize, x0 + dx)); y1 = min(vs.height, max(y0 + minSize, y1 + dy))
                    default: x1 = min(vs.width, max(x0 + minSize, x1 + dx)); y1 = min(vs.height, max(y0 + minSize, y1 + dy))
                    }
                    viewModel.cropRect = CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
                }
                .onEnded { _ in dragStartRect = viewModel.cropRect ?? CGRect(origin: .zero, size: viewModel.videoSize) }
            )
    }
}

// MARK: - Main preview view

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
                let frame = videoDisplayFrame(in: geometry)
                let scale = displayScale(in: geometry)

                ZStack {
                    // Dark canvas
                    Color(white: 0.12)

                    // Checkerboard at video rect (shows through rounded corners)
                    CheckerboardView()
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)

                    // Video layer — clipped to crop region when crop is active
                    let (layerSize, layerOffset) = videoLayerSizeAndOffset(in: geometry)
                    let cropActive = activeCropRect != nil
                    let displayRadius = viewModel.cornerRadius * scale
                    ZStack {
                        RoundedVideoLayerView(
                            player: viewModel.player!,
                            cornerRadius: cropActive ? 0 : viewModel.cornerRadius,
                            videoSize: viewModel.videoSize
                        )
                        .frame(width: layerSize.width, height: layerSize.height)
                        .offset(layerOffset)
                    }
                    .frame(width: frame.width, height: frame.height)
                    .clipShape(RoundedRectangle(cornerRadius: cropActive ? displayRadius : 0))
                    .position(x: frame.midX, y: frame.midY)

                    // PNG overlay
                    if viewModel.overlayImage != nil && !viewModel.isCropMode {
                        OverlayLayerView(
                            viewModel: viewModel,
                            videoFrame: frame,
                            scale: scale
                        )
                    }

                    // Crop overlay
                    if viewModel.isCropMode {
                        CropOverlayView(viewModel: viewModel, videoFrame: frame, scale: scale)
                    }

                    // Corner radius handle (hidden in crop mode)
                    if !viewModel.isCropMode {
                        handleOverlay(in: geometry)
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

    // MARK: - Handle overlay

    @ViewBuilder
    private func handleOverlay(in geometry: GeometryProxy) -> some View {
        let frame = videoDisplayFrame(in: geometry)
        let scale = displayScale(in: geometry)
        let handleSize: CGFloat = 20
        let handlePos = CGPoint(
            x: frame.minX + viewModel.cornerRadius * scale,
            y: frame.minY + 20
        )

        Circle()
            .fill(Color.yellow)
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

    // MARK: - Layout helpers

    private func displayScale(in geometry: GeometryProxy) -> CGFloat {
        let frame = videoDisplayFrame(in: geometry)
        let refWidth = activeCropRect?.width ?? viewModel.videoSize.width
        guard refWidth > 0 else { return 1 }
        return frame.width / refWidth
    }

    /// The effective size shown in the preview (crop size when active, full video otherwise).
    private var activeCropRect: CGRect? {
        viewModel.isCropMode ? nil : viewModel.cropRect
    }

    private func videoDisplayFrame(in geometry: GeometryProxy) -> CGRect {
        guard viewModel.videoSize.width > 0, viewModel.videoSize.height > 0 else { return .zero }
        let padding: CGFloat = 40
        let availableSize = CGSize(width: geometry.size.width - padding * 2, height: geometry.size.height - padding * 2)
        let refSize = activeCropRect?.size ?? viewModel.videoSize

        let ratio = min(availableSize.width / refSize.width, availableSize.height / refSize.height)
        let w = refSize.width * ratio
        let h = refSize.height * ratio
        return CGRect(x: (geometry.size.width - w) / 2, y: (geometry.size.height - h) / 2, width: w, height: h)
    }

    /// When crop is active, the full video layer is larger than the display frame and offset so the crop region shows.
    private func videoLayerSizeAndOffset(in geometry: GeometryProxy) -> (CGSize, CGSize) {
        let frame = videoDisplayFrame(in: geometry)
        guard let crop = activeCropRect, crop.width > 0 else {
            return (CGSize(width: frame.width, height: frame.height), .zero)
        }
        let scale = frame.width / crop.width
        let fullW = viewModel.videoSize.width * scale
        let fullH = viewModel.videoSize.height * scale
        let offsetX = (viewModel.videoSize.width / 2 - crop.midX) * scale
        let offsetY = (viewModel.videoSize.height / 2 - crop.midY) * scale
        return (CGSize(width: fullW, height: fullH), CGSize(width: offsetX, height: offsetY))
    }
}
