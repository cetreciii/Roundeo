import SwiftUI

struct DropZoneView: View {
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
