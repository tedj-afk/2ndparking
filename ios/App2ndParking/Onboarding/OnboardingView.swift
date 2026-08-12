import SwiftUI

/// Three-page swipeable intro shown right after the splash, before sign-up.
struct OnboardingView: View {
    let onFinished: () -> Void

    @State private var pageIndex: Int = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "magnifyingglass",
            accessory: "building.2.fill",
            title: "Find hidden parking",
            message: "Search private spots inside residential towers in West Bay, The Pearl, Lusail and beyond — hourly or daily."
        ),
        OnboardingPage(
            icon: "qrcode",
            accessory: "bolt.fill",
            title: "Book in seconds",
            message: "Reserve, pay and get a QR Access Pass instantly. Show it to building security and drive right in."
        ),
        OnboardingPage(
            icon: "banknote.fill",
            accessory: "key.fill",
            title: "Earn from your spot",
            message: "Have an empty parking spot? List it in minutes and turn it into steady income — you stay in control."
        )
    ]

    private var isLastPage: Bool { pageIndex == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if !isLastPage {
                    TextLinkButton(title: "Skip", color: .inkSecondary, size: 15) {
                        onFinished()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .frame(height: 44)

            TabView(selection: $pageIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page, isActive: pageIndex == index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: pageIndex)

            // Custom page dots
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == pageIndex ? Color.brandOrange : Color.borderGray)
                        .frame(width: index == pageIndex ? 26 : 8, height: 8)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: pageIndex)
                }
            }
            .padding(.bottom, 26)

            PrimaryButton(title: isLastPage ? "Get Started" : "Next") {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if isLastPage {
                    onFinished()
                } else {
                    withAnimation {
                        pageIndex += 1
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
        .background(Color.white)
    }
}

struct OnboardingPage {
    let icon: String
    let accessory: String
    let title: String
    let message: String
}

/// One onboarding page: layered icon illustration + copy.
struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool

    @State private var animated: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            illustration
                .scaleEffect(animated ? 1 : 0.8)
                .opacity(animated ? 1 : 0)

            Spacer().frame(height: 48)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkPrimary)
                Text(page.message)
                    .font(.system(size: 15.5))
                    .foregroundStyle(Color.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 34)
            }
            .opacity(animated ? 1 : 0)
            .offset(y: animated ? 0 : 18)

            Spacer()
        }
        .onChange(of: isActive) { _, nowActive in
            if nowActive {
                runEntrance()
            }
        }
        .onAppear {
            if isActive {
                runEntrance()
            }
        }
    }

    private func runEntrance() {
        animated = false
        withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.08)) {
            animated = true
        }
    }

    private var illustration: some View {
        ZStack {
            Circle()
                .fill(Color.orangeFaint)
                .frame(width: 220, height: 220)
            Circle()
                .fill(Color.orangePale)
                .frame(width: 160, height: 160)

            Image(systemName: page.icon)
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(Color.brandOrange)

            Image(systemName: page.accessory)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Color.inkPrimary)
                .clipShape(.circle)
                .overlay {
                    Circle().strokeBorder(Color.white, lineWidth: 3.5)
                }
                .offset(x: 74, y: -64)
        }
    }
}
