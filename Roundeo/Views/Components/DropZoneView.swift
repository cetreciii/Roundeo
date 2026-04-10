import SwiftUI

struct DropZoneView: View {
    let isDragTargeted: Bool
    let onBrowse: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "video.fill.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(isDragTargeted ? Color.primary : Color.secondary)

            Text("Drop a video here")
                .font(DesignSystem.Typography.heading2)
                .foregroundStyle(isDragTargeted ? Color.primary : Color.secondary)

            Text("or")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.tertiary)

            Button("Browse files", action: onBrowse)
                .buttonStyle(.bordered)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: DesignSystem.Borders.medium, dash: [8, 4])
                )
                .foregroundStyle(isDragTargeted ? DesignSystem.Colors.accent : DesignSystem.Colors.border)
                .padding(DesignSystem.Spacing.xl)
        }
        .background(DesignSystem.Colors.canvasBackground)
        .animation(DesignSystem.Animations.quick, value: isDragTargeted)
        .accentColor(DesignSystem.Colors.accent)
    }
}
