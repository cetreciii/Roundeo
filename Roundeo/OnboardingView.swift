import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool

    var body: some View {
        ZStack {
            Color(white: 0.12)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "rectangle.roundcorners.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.blue)

                VStack(spacing: 12) {
                    Text("Welcome to Roundeo")
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    Text("Transform your videos with rounded corners")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 20) {
                    OnboardingStep(
                        number: 1,
                        title: "Drop a video",
                        description: "Drag and drop your video into the window, or click + to browse.",
                        icon: "arrow.down.doc"
                    )

                    OnboardingStep(
                        number: 2,
                        title: "Adjust corners",
                        description: "Pick a preset or fine-tune with the slider and the yellow handle.",
                        icon: "slider.horizontal.3"
                    )

                    OnboardingStep(
                        number: 3,
                        title: "Export",
                        description: "Export your video with transparent rounded corners. Works with any aspect ratio.",
                        icon: "square.and.arrow.up"
                    )
                }
                .padding(24)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)

                Spacer()

                Button(action: {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    withAnimation {
                        showOnboarding = false
                    }
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 40)
            }
            .padding(40)
            .frame(maxWidth: 480)
        }
    }
}

struct OnboardingStep: View {
    let number: Int
    let title: String
    let description: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(number)")
                .font(.system(.body, design: .rounded).weight(.bold))
                .frame(width: 32, height: 32)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
            }
        }
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
}
