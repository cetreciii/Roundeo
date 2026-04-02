import SwiftUI

struct OverlayLayerView: View {
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
                    .stroke(DesignSystem.Colors.accent, lineWidth: 1)
                }
                if isSnappedV {
                    Path { p in
                        p.move(to: CGPoint(x: videoFrame.minX, y: videoFrame.midY))
                        p.addLine(to: CGPoint(x: videoFrame.maxX, y: videoFrame.midY))
                    }
                    .stroke(DesignSystem.Colors.accent, lineWidth: 1)
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

struct ResizeHandle: View {
    let position: CGPoint
    let overlayCenter: CGPoint
    @ObservedObject var viewModel: VideoViewModel
    @Binding var dragStartScale: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Colors.accentLight)
            Circle()
                .stroke(Color.white, lineWidth: 1)
        }
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
