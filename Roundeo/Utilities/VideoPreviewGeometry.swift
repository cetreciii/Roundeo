import Foundation
import CoreGraphics

struct VideoPreviewGeometry {
    let videoSize: CGSize
    let cropRect: CGRect?  // nil when in crop mode or no crop active
    let canvasSize: CGSize

    static let padding: CGFloat = 80

    /// The effective size shown in the preview (crop size when active, full video otherwise).
    var activeCropRect: CGRect? {
        cropRect
    }

    /// The display frame for the video within the canvas.
    var displayFrame: CGRect {
        guard videoSize.width > 0, videoSize.height > 0 else { return .zero }
        let availableSize = CGSize(
            width: canvasSize.width - Self.padding * 2,
            height: canvasSize.height - Self.padding * 2
        )
        let refSize = activeCropRect?.size ?? videoSize

        let ratio = min(
            availableSize.width / refSize.width,
            availableSize.height / refSize.height
        )
        let w = refSize.width * ratio
        let h = refSize.height * ratio
        return CGRect(
            x: (canvasSize.width - w) / 2,
            y: (canvasSize.height - h) / 2,
            width: w,
            height: h
        )
    }

    /// Scale factor from video space to display space.
    var scale: CGFloat {
        let frame = displayFrame
        let refWidth = activeCropRect?.width ?? videoSize.width
        guard refWidth > 0 else { return 1 }
        return frame.width / refWidth
    }

    /// When crop is active, the full video layer is larger than the display frame and offset.
    func layerSizeAndOffset() -> (CGSize, CGSize) {
        let frame = displayFrame
        guard let crop = activeCropRect, crop.width > 0 else {
            return (CGSize(width: frame.width, height: frame.height), .zero)
        }
        let s = frame.width / crop.width
        let fullW = videoSize.width * s
        let fullH = videoSize.height * s
        let offsetX = (videoSize.width / 2 - crop.midX) * s
        let offsetY = (videoSize.height / 2 - crop.midY) * s
        return (CGSize(width: fullW, height: fullH), CGSize(width: offsetX, height: offsetY))
    }
}
