import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool

    var body: some View {
        ZStack {
            DesignSystem.Colors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.xl2) {
                Spacer()

                Image(systemName: "rectangle.roundcorners.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(DesignSystem.Colors.accent)

                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("Welcome to Roundeo")
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    Text("Transform your videos with rounded corners")
                        .font(DesignSystem.Typography.heading2)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    OnboardingStep(
                        number: 1,
                        title: "Load a video",
                        description: "Drag and drop a video into the window, or use the Add video button in the toolbar.",
                        icon: "arrow.down.doc"
                    )

                    OnboardingStep(
                        number: 2,
                        title: "Customize",
                        description: "Adjust corner radius with the slider, crop to any region, and optionally add a device frame overlay.",
                        icon: "slider.horizontal.3"
                    )

                    OnboardingStep(
                        number: 3,
                        title: "Export",
                        description: "Export as .mov with true transparency and HEVC codec. Set custom dimensions or use the video's natural size.",
                        icon: "square.and.arrow.up"
                    )
                }
                .padding(DesignSystem.Spacing.xl)
                .background(Color.white.opacity(0.06))
                .cornerRadius(DesignSystem.CornerRadius.xl)

                Spacer()

                Button(action: {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    withAnimation(DesignSystem.Animations.standard) {
                        showOnboarding = false
                    }
                }) {
                    Text("Get Started")
                        .font(DesignSystem.Typography.heading3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.accent)
                        .foregroundColor(.white)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                }
                .buttonStyle(.plain)
                .padding(.bottom, DesignSystem.Spacing.xl2)
            }
            .padding(DesignSystem.Spacing.xl2)
            .frame(maxWidth: 480)
        }
        .accentColor(DesignSystem.Colors.accent)
    }
}

struct OnboardingStep: View {
    let number: Int
    let title: String
    let description: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Text("\(number)")
                .font(.system(.body, design: .rounded).weight(.bold))
                .frame(width: DesignSystem.Sizing.buttonRegular, height: DesignSystem.Sizing.buttonRegular)
                .background(DesignSystem.Colors.accent)
                .foregroundColor(.white)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(title)
                        .font(DesignSystem.Typography.heading3)
                        .foregroundStyle(.white)
                    Image(systemName: icon)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.accent)
                }
                Text(description)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
            }
        }
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
}
