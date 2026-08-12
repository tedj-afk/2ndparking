import SwiftUI

/// Animated brand splash shown on every cold launch.
struct SplashView: View {
    let onFinished: () -> Void

    @State private var markScale: CGFloat = 0.6
    @State private var markOpacity: Double = 0
    @State private var wordmarkVisible: Bool = false
    @State private var taglineVisible: Bool = false
    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            Color.brandOrange.ignoresSafeArea()

            // Soft radial glow behind the mark
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 340, height: 340)
                .blur(radius: 60)
                .scaleEffect(pulse ? 1.15 : 0.9)
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)

            VStack(spacing: 22) {
                Text("P")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.brandOrange)
                    .frame(width: 108, height: 108)
                    .background(Color.white)
                    .clipShape(.rect(cornerRadius: 28))
                    .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
                    .scaleEffect(markScale)
                    .opacity(markOpacity)

                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        Text("2nd")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                        Text("Parking")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .opacity(wordmarkVisible ? 1 : 0)
                    .offset(y: wordmarkVisible ? 0 : 14)

                    Text("Access to a parking spot easily")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .opacity(taglineVisible ? 1 : 0)
                }
            }
        }
        .onAppear {
            pulse = true
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
                markScale = 1
                markOpacity = 1
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35)) {
                wordmarkVisible = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.65)) {
                taglineVisible = true
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(2))
            onFinished()
        }
    }
}
