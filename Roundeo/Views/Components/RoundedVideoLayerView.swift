import SwiftUI
import AVKit

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
