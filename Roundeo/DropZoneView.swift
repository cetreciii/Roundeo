import SwiftUI

struct DropZoneView: View {
    let isDragTargeted: Bool
    let onBrowse: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "rectangle.roundcorners.fill")
                .font(.system(size: 56))
                .foregroundStyle(isDragTargeted ? .white : .secondary)

            Text("Drop a video here")
                .font(DesignSystem.Typography.heading2)
                .foregroundStyle(isDragTargeted ? .white : .secondary)

            Text("or")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.tertiary)

            Button("Browse Files", action: onBrowse)
                .buttonStyle(.bordered)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: DesignSystem.Borders.medium, dash: [8, 4])
                )
                .foregroundStyle(isDragTargeted ? DesignSystem.Colors.accent : Color.white.opacity(0.15))
                .padding(DesignSystem.Spacing.xl)
        }
        .background(DesignSystem.Colors.canvasBackground)
        .animation(DesignSystem.Animations.quick, value: isDragTargeted)
        .accentColor(DesignSystem.Colors.accent)
    }
}
