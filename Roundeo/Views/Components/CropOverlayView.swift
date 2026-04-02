import SwiftUI

struct CropOverlayView: View {
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

struct CropCornerHandle: View {
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
