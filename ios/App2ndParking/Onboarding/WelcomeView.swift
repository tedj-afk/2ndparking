import SwiftUI

/// Welcome screen with Apple / Google sign-up (mocked for the prototype).
struct WelcomeView: View {
    let onSignedIn: () -> Void

    @State private var appeared: Bool = false
    @State private var signingInWith: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            heroImage

            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    BrandLogo()
                    Text("Parking made simple")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkPrimary)
                        .multilineTextAlignment(.center)
                    Text("Find, book and access private parking spots in residential towers across Doha.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.inkSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 28)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer()

                VStack(spacing: 12) {
                    authButton(
                        id: "apple",
                        icon: "apple.logo",
                        title: "Sign up with Apple",
                        foreground: .white,
                        background: Color.inkPrimary
                    )
                    authButton(
                        id: "google",
                        icon: "g.circle.fill",
                        title: "Sign up with Google",
                        foreground: Color.inkPrimary,
                        background: Color.white,
                        bordered: true
                    )

                    Text("By continuing you agree to our Terms of Service and Privacy Policy")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.inkTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                        .padding(.top, 6)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 26)
            }
            .padding(.top, 26)
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.1)) {
                appeared = true
            }
        }
    }

    private var heroImage: some View {
        Color.cardGray
            .frame(height: 320)
            .overlay {
                Image("underground_parking_garage")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .allowsHitTesting(false)
            }
            .overlay {
                LinearGradient(
                    colors: [.clear, .clear, Color.white.opacity(0.35), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipped()
    }

    private func authButton(
        id: String,
        icon: String,
        title: String,
        foreground: Color,
        background: Color,
        bordered: Bool = false
    ) -> some View {
        Button {
            guard signingInWith == nil else { return }
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            signingInWith = id
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                onSignedIn()
            }
        } label: {
            HStack(spacing: 10) {
                if signingInWith == id {
                    ProgressView()
                        .tint(foreground)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .medium))
                }
                Text(signingInWith == id ? "Signing up…" : title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(background)
            .clipShape(.rect(cornerRadius: 16))
            .overlay {
                if bordered {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.borderGray, lineWidth: 1.5)
                }
            }
        }
        .disabled(signingInWith != nil)
        .opacity(signingInWith != nil && signingInWith != id ? 0.5 : 1)
    }
}
