import SwiftUI

/// Roundeo Design System
/// Centralizes colors, typography, spacing, and component styles
struct DesignSystem {

    // MARK: - Colors

    struct Colors {
        /// Primary accent color - dark green
        static let accent = Color(hex: "0A2903")

        /// Light green accent for secondary interactive elements
        static let accentLight = Color(hex: "347232")

        /// Semantic colors
        static let success = Color(hex: "34C759")
        static let warning = Color(hex: "FF9500")
        static let error = Color(hex: "FF3B30")

        /// Neutral colors
        static let background = Color(white: 0.95)
        static let surfacePrimary = Color(white: 0.98)
        static let surfaceSecondary = Color(white: 0.92)
        static let canvasBackground = Color(white: 0.12)
        static let border = Color(white: 0.2)

        /// Text colors
        static let textPrimary = Color(white: 0.1)
        static let textSecondary = Color(white: 0.4)
        static let textTertiary = Color(white: 0.6)
        static let textInverse = Color(white: 0.95)

        /// Interactive states
        static let buttonHover = Color(white: 0.88)
        static let buttonActive = Color(white: 0.82)
        static let disabledOverlay = Color(white: 0.0).opacity(0.4)
    }

    // MARK: - Typography

    struct Typography {
        /// Large heading, 20pt
        static let heading1 = Font.system(size: 20, weight: .semibold)

        /// Medium heading, 16pt
        static let heading2 = Font.system(size: 16, weight: .semibold)

        /// Small heading, 14pt
        static let heading3 = Font.system(size: 14, weight: .semibold)

        /// Body text, 13pt (macOS standard)
        static let body = Font.system(size: 13, weight: .regular)

        /// Body text with emphasis, 13pt bold
        static let bodyEmphasis = Font.system(size: 13, weight: .semibold)

        /// Small caption, 11pt
        static let caption = Font.system(size: 11, weight: .regular)

        /// Small caption with emphasis, 11pt semibold
        static let captionEmphasis = Font.system(size: 11, weight: .semibold)
    }

    // MARK: - Spacing

    struct Spacing {
        /// Extra small: 4pt
        static let xs: CGFloat = 4

        /// Small: 8pt
        static let sm: CGFloat = 8

        /// Medium: 12pt
        static let md: CGFloat = 12

        /// Large: 16pt
        static let lg: CGFloat = 16

        /// Extra large: 24pt
        static let xl: CGFloat = 24

        /// 2x large: 32pt
        static let xl2: CGFloat = 32
    }

    // MARK: - Sizing

    struct Sizing {
        /// Small button height
        static let buttonSmall: CGFloat = 24

        /// Regular button height
        static let buttonRegular: CGFloat = 32

        /// Large button height
        static let buttonLarge: CGFloat = 40

        /// Standard icon size
        static let iconStandard: CGFloat = 16

        /// Large icon size
        static let iconLarge: CGFloat = 24
    }

    // MARK: - Corner Radius

    struct CornerRadius {
        /// Extra small: 2pt
        static let xs: CGFloat = 2

        /// Small: 4pt
        static let sm: CGFloat = 4

        /// Medium: 6pt
        static let md: CGFloat = 6

        /// Large: 8pt
        static let lg: CGFloat = 8

        /// Extra large: 12pt
        static let xl: CGFloat = 12
    }

    // MARK: - Borders

    struct Borders {
        /// Thin border: 0.5pt
        static let thin: CGFloat = 0.5

        /// Regular border: 1pt
        static let regular: CGFloat = 1

        /// Medium border: 2pt
        static let medium: CGFloat = 2
    }

    // MARK: - Shadows

    struct Shadows {
        /// Small shadow for subtle elevation
        static func small(_ color: Color = .black) -> [Shadow] {
            [Shadow(color: color.opacity(0.1), radius: 2, x: 0, y: 1)]
        }

        /// Medium shadow for component elevation
        static func medium(_ color: Color = .black) -> [Shadow] {
            [Shadow(color: color.opacity(0.15), radius: 4, x: 0, y: 2)]
        }

        /// Large shadow for modal/overlay elevation
        static func large(_ color: Color = .black) -> [Shadow] {
            [Shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)]
        }
    }

    // MARK: - Animations

    struct Animations {
        /// Quick interaction animation: 0.15s
        static let quick = Animation.easeInOut(duration: 0.15)

        /// Standard animation: 0.3s
        static let standard = Animation.easeInOut(duration: 0.3)

        /// Slow animation for emphasis: 0.5s
        static let slow = Animation.easeInOut(duration: 0.5)
    }
}

// MARK: - Color Helper Extension

extension Color {
    /// Initialize color from hex string
    /// - Parameter hex: Hex color code (e.g., "1F3D18")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}

// MARK: - Shadow Helper Extension

extension View {
    /// Apply a shadow from the design system
    /// - Parameter shadow: Array of Shadow values from DesignSystem.Shadows
    func designSystemShadow(_ shadows: [Shadow]) -> some View {
        var result = AnyView(self)
        for shadow in shadows {
            result = AnyView(result.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y))
        }
        return result
    }
}

// MARK: - Shadow Structure

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

#Preview {
    VStack(spacing: DesignSystem.Spacing.lg) {
        Text("Design System Preview")
            .font(DesignSystem.Typography.heading1)
            .foregroundColor(DesignSystem.Colors.textPrimary)

        HStack(spacing: DesignSystem.Spacing.md) {
            Circle()
                .fill(DesignSystem.Colors.accent)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Accent Color")
                    .font(DesignSystem.Typography.bodyEmphasis)
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Text("HEX: 1F3D18")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.surfacePrimary)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .border(DesignSystem.Colors.border)

        HStack(spacing: DesignSystem.Spacing.md) {
            ForEach([DesignSystem.Colors.success, DesignSystem.Colors.warning, DesignSystem.Colors.error], id: \.self) { color in
                Circle()
                    .fill(color)
                    .frame(width: 24, height: 24)
            }
        }

        Spacer()
    }
    .padding(DesignSystem.Spacing.lg)
    .background(DesignSystem.Colors.background)
}
