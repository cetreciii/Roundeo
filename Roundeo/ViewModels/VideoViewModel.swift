import SwiftUI
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Combine
import UniformTypeIdentifiers

@MainActor
class VideoViewModel: ObservableObject {
    @Published var url: URL?
    @Published var player: AVPlayer?
    @Published var cornerRadius: Double = 0
    @Published var videoSize: CGSize = .zero
    @Published var isExporting: Bool = false
    @Published var exportProgress: Double = 0
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var showOnboarding: Bool = false
    @Published var exportWidthText: String = ""
    @Published var exportHeightText: String = ""
    var isSeeking: Bool = false

    // Crop
    @Published var cropRect: CGRect? = nil  // video pixels, Y-down; nil = no crop
    @Published var isCropMode: Bool = false

    // Overlay
    @Published var overlayImage: NSImage?
    @Published var overlayURL: URL?
    @Published var overlayOffset: CGSize = .zero // offset from center, in video pixels
    @Published var overlayScale: CGFloat = 1.0 // scale factor for overlay size

    private var exportSession: AVAssetExportSession?
    private var timeObserver: Any?

    init() {
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        self.showOnboarding = !hasSeenOnboarding
    }

    func loadVideo(url: URL) {
        if let observer = timeObserver, let player = player {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }

        self.url = url
        self.cornerRadius = 0
        self.isPlaying = false
        self.currentTime = 0
        self.duration = 0
        self.cropRect = nil
        self.isCropMode = false

        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let newPlayer = AVPlayer(playerItem: playerItem)
        self.player = newPlayer

        Task {
            do {
                if let track = try await asset.loadTracks(withMediaType: .video).first {
                    let size = try await track.load(.naturalSize)
                    let transform = try await track.load(.preferredTransform)
                    let transformed = size.applying(transform)
                    self.videoSize = CGSize(width: abs(transformed.width), height: abs(transformed.height))
                }
                let dur = try await asset.load(.duration)
                self.duration = dur.seconds
            } catch {
                print("Error loading video info: \(error)")
            }
        }

        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self = self, !self.isSeeking else { return }
                self.currentTime = time.seconds
            }
        }
    }

    var maxRadius: Double {
        let size = cropRect?.size ?? videoSize
        return min(size.width, size.height) / 2
    }

    func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    // MARK: - Overlay

    /// Overlay scaled to fit within the video bounds, maintaining aspect ratio.
    var overlayFittedSize: CGSize {
        guard let img = overlayImage,
              videoSize.width > 0, videoSize.height > 0 else { return .zero }
        let imgSize = img.size
        guard imgSize.width > 0, imgSize.height > 0 else { return .zero }
        let scale = min(videoSize.width / imgSize.width, videoSize.height / imgSize.height)
        return CGSize(width: imgSize.width * scale, height: imgSize.height * scale)
    }

    func pickOverlay() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .image]
        panel.allowsMultipleSelection = false
        panel.message = "Choose a PNG overlay (e.g. a device frame)"
        panel.begin { response in
            if response == .OK, let url = panel.url {
                Task { @MainActor in
                    self.loadOverlay(url: url)
                }
            }
        }
    }

    func loadOverlay(url: URL) {
        guard let image = NSImage(contentsOf: url) else { return }
        self.overlayImage = image
        self.overlayURL = url
        self.overlayOffset = .zero
    }

    func removeOverlay() {
        self.overlayImage = nil
        self.overlayURL = nil
        self.overlayOffset = .zero
        self.overlayScale = 1.0
    }

    // MARK: - Export

    func exportVideo() {
        guard url != nil else { return }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.quickTimeMovie]
        savePanel.nameFieldStringValue = "rounded_video.mov"

        savePanel.begin { response in
            if response == .OK, let outputURL = savePanel.url {
                Task {
                    await self.performExport(to: outputURL)
                }
            }
        }
    }

    private static func createRoundedRectMask(size: CGSize, radius: CGFloat) -> CIImage? {
        let width = Int(size.width)
        let height = Int(size.height)
        guard width > 0, height > 0, radius > 0 else { return nil }

        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        ctx.setFillColor(CGColor(gray: 0, alpha: 1))
        ctx.fill(CGRect(origin: .zero, size: size))

        ctx.setFillColor(CGColor(gray: 1, alpha: 1))
        let path = CGPath(
            roundedRect: CGRect(origin: .zero, size: size),
            cornerWidth: radius,
            cornerHeight: radius,
            transform: nil
        )
        ctx.addPath(path)
        ctx.fillPath()

        guard let cgImage = ctx.makeImage() else { return nil }
        return CIImage(cgImage: cgImage)
    }

    /// Returns the export canvas size and the video's origin within that canvas.
    /// When the overlay extends beyond the video bounds, the canvas grows to fit both.
    private static func exportCanvas(
        videoSize: CGSize,
        overlaySize: CGSize,   // already scaled (fittedSize * overlayScale)
        overlayOffset: CGSize  // in video pixels, Y-down (SwiftUI convention)
    ) -> (canvasSize: CGSize, videoOrigin: CGPoint) {
        guard overlaySize.width > 0, overlaySize.height > 0 else {
            return (videoSize, .zero)
        }
        // Convert offset to CIImage coords (Y-up): negate height
        let overlayCenterX = videoSize.width / 2 + overlayOffset.width
        let overlayCenterY = videoSize.height / 2 - overlayOffset.height

        let overlayMinX = overlayCenterX - overlaySize.width / 2
        let overlayMinY = overlayCenterY - overlaySize.height / 2
        let overlayMaxX = overlayCenterX + overlaySize.width / 2
        let overlayMaxY = overlayCenterY + overlaySize.height / 2

        let minX = min(0, overlayMinX)
        let minY = min(0, overlayMinY)
        let maxX = max(videoSize.width, overlayMaxX)
        let maxY = max(videoSize.height, overlayMaxY)

        return (
            CGSize(width: maxX - minX, height: maxY - minY),
            CGPoint(x: -minX, y: -minY)
        )
    }

    private func performExport(to outputURL: URL) async {
        guard let url = url else { return }

        // Remove existing file so AVAssetExportSession doesn't fail
        try? FileManager.default.removeItem(at: outputURL)

        let asset = AVURLAsset(url: url)

        let radius = self.cornerRadius
        let capturedCrop = self.cropRect
        let expectedSize = self.videoSize
        // Size after crop (used for mask, canvas, and overlay offset)
        let outputSize = capturedCrop?.size ?? expectedSize

        let trackTransform: CGAffineTransform
        if let track = try? await asset.loadTracks(withMediaType: .video).first,
           let t = try? await track.load(.preferredTransform) {
            trackTransform = t
        } else {
            trackTransform = .identity
        }

        // Rounded-corners mask (output-sized, applied after crop)
        let mask = Self.createRoundedRectMask(size: outputSize, radius: CGFloat(radius))

        // Pre-compute overlay CIImage scaled to its final pixel size
        let overlayCI: CIImage?
        let capturedOffset = self.overlayOffset
        let capturedFitted = self.overlayFittedSize
        let capturedOverlayScale = self.overlayScale
        let capturedOverlayURL = self.overlayURL
        let scaledOverlaySize = CGSize(
            width: capturedFitted.width * capturedOverlayScale,
            height: capturedFitted.height * capturedOverlayScale
        )
        if capturedFitted.width > 0 {
            // Load via URL for full-resolution access (handles large PNGs that cgImage(forProposedRect:) may fail on)
            let ci: CIImage? = capturedOverlayURL.flatMap { CIImage(contentsOf: $0) }
                ?? self.overlayImage.flatMap { nsImage -> CIImage? in
                    var rect = NSRect(origin: .zero, size: nsImage.size)
                    return nsImage.cgImage(forProposedRect: &rect, context: nil, hints: nil).map { CIImage(cgImage: $0) }
                }
            if let ci = ci {
                let sx = scaledOverlaySize.width / ci.extent.width
                let sy = scaledOverlaySize.height / ci.extent.height
                overlayCI = ci.transformed(by: CGAffineTransform(scaleX: sx, y: sy))
            } else {
                overlayCI = nil
            }
        } else {
            overlayCI = nil
        }

        // Calculate canvas that fits both (cropped) video and (possibly larger) overlay
        let (canvasSize, videoOrigin) = Self.exportCanvas(
            videoSize: outputSize,
            overlaySize: overlayCI != nil ? scaledOverlaySize : .zero,
            overlayOffset: capturedOffset
        )

        // Determine final render size (custom if set, otherwise natural canvas size)
        let customW = Int(self.exportWidthText) ?? 0
        let customH = Int(self.exportHeightText) ?? 0
        let renderSize: CGSize
        if customW > 0 && customH > 0 {
            renderSize = CGSize(width: customW, height: customH)
        } else {
            renderSize = canvasSize
        }

        let composition = AVMutableVideoComposition(asset: asset) { request in
            var image = request.sourceImage

            // Vertical videos: sourceImage is in pre-transform space, apply transform
            if abs(image.extent.width - expectedSize.width) > 1
                || abs(image.extent.height - expectedSize.height) > 1
            {
                image = image.transformed(by: trackTransform)
                let origin = image.extent.origin
                if origin.x != 0 || origin.y != 0 {
                    image = image.transformed(by: CGAffineTransform(translationX: -origin.x, y: -origin.y))
                }
            }

            // Apply crop (convert from Y-down to CIImage Y-up)
            if let crop = capturedCrop {
                let ciCropRect = CGRect(
                    x: crop.minX,
                    y: expectedSize.height - crop.maxY,
                    width: crop.width,
                    height: crop.height
                )
                image = image.cropped(to: ciCropRect)
                    .transformed(by: CGAffineTransform(translationX: -ciCropRect.minX, y: -ciCropRect.minY))
            }

            // Apply rounded corners (in output coordinate space, at origin 0,0)
            var roundedVideo: CIImage
            if let mask = mask {
                let background = CIImage(color: .clear).cropped(to: image.extent)
                roundedVideo = image.applyingFilter("CIBlendWithMask", parameters: [
                    kCIInputMaskImageKey: mask,
                    kCIInputBackgroundImageKey: background
                ])
            } else {
                roundedVideo = image
            }

            // Place rounded video into canvas at its computed origin
            let canvas = CIImage(color: .clear).cropped(to: CGRect(origin: .zero, size: canvasSize))
            let placedVideo = roundedVideo
                .transformed(by: CGAffineTransform(translationX: videoOrigin.x, y: videoOrigin.y))
            var output = placedVideo.composited(over: canvas)

            // Composite overlay at its position within the canvas
            if let overlay = overlayCI {
                // Overlay center in output coords (CIImage Y-up)
                let overlayCenterX = outputSize.width / 2 + capturedOffset.width
                let overlayCenterY = outputSize.height / 2 - capturedOffset.height
                // Translate to canvas coords
                let overlayX = videoOrigin.x + overlayCenterX - overlay.extent.width / 2
                let overlayY = videoOrigin.y + overlayCenterY - overlay.extent.height / 2
                let positioned = overlay.transformed(by: CGAffineTransform(translationX: overlayX, y: overlayY))
                output = positioned.composited(over: output)
            }

            // Scale to custom render size if requested (fit within bounds, maintain aspect ratio)
            if renderSize != canvasSize {
                let sx = renderSize.width / canvasSize.width
                let sy = renderSize.height / canvasSize.height
                let s = min(sx, sy)
                let scaledW = canvasSize.width * s
                let scaledH = canvasSize.height * s
                let offsetX = (renderSize.width - scaledW) / 2
                let offsetY = (renderSize.height - scaledH) / 2
                output = output
                    .transformed(by: CGAffineTransform(scaleX: s, y: s))
                    .transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
            }

            request.finish(with: output, context: nil)
        }
        composition.renderSize = renderSize

        let preset = AVAssetExportPresetHEVCHighestQualityWithAlpha
        guard let session = AVAssetExportSession(asset: asset, presetName: preset) else {
            self.alertMessage = "Failed to create export session"
            self.showAlert = true
            return
        }

        self.exportSession = session
        session.videoComposition = composition
        session.outputFileType = .mov
        session.outputURL = outputURL

        self.isExporting = true
        self.exportProgress = 0

        let progressTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                let progress = session.progress
                await MainActor.run {
                    self.exportProgress = Double(progress)
                }
                if session.status != .exporting { break }
            }
        }

        do {
            try await session.export(to: outputURL, as: .mov)
            progressTask.cancel()
            self.isExporting = false
            self.alertMessage = "Export completed successfully!"
            self.showAlert = true
        } catch {
            progressTask.cancel()
            self.isExporting = false
            self.alertMessage = "Export failed: \(error.localizedDescription)"
            self.showAlert = true
        }
    }
}
