import SwiftUI

/// Thin wizard progress bar (orange fill over pale track).
struct WizardProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.orangePale)
                Capsule()
                    .fill(Color.brandOrange)
                    .frame(width: max(12, geo.size.width * progress))
            }
        }
        .frame(height: 6)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: progress)
    }
}

/// Horizontal stepper: Requested → Accepted → Pay deposit → Sign.
struct StatusStepper: View {
    let stages: [String]
    /// Index of the current stage (dots before it are filled, current is outlined orange).
    let currentIndex: Int
    var pendingLabelOverride: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                VStack(spacing: 8) {
                    ZStack {
                        if index < currentIndex {
                            Circle()
                                .fill(Color.brandOrange)
                                .frame(width: 22, height: 22)
                        } else if index == currentIndex {
                            Circle()
                                .fill(Color.orangeFaint)
                                .frame(width: 22, height: 22)
                                .overlay(Circle().stroke(Color.brandOrange, lineWidth: 2.5))
                        } else {
                            Circle()
                                .fill(Color.orangePale)
                                .frame(width: 18, height: 18)
                        }
                    }
                    .frame(height: 24)
                    Text(index == currentIndex ? (pendingLabelOverride ?? stage) : stage)
                        .font(.system(size: 12, weight: index <= currentIndex ? .semibold : .regular))
                        .foregroundStyle(index <= currentIndex ? Color.brandOrange : Color.orangePale.opacity(1))
                        .foregroundStyle(index <= currentIndex ? Color.brandOrange : Color(hex: 0xF5C9A8))
                        .lineLimit(1)
                        .fixedSize()
                }
                .frame(maxWidth: .infinity)
                .overlay(alignment: .top) {
                    if index < stages.count - 1 {
                        Rectangle()
                            .fill(index < currentIndex ? Color.brandOrange : Color.orangePale)
                            .frame(height: 2.5)
                            .offset(y: 11)
                            .padding(.leading, 60)
                            .padding(.trailing, -32)
                    }
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: currentIndex)
    }
}

/// Centered modal card: icon + title + message + up to two buttons.
struct ConfirmationDialogView: View {
    enum DialogIcon {
        case warning, success, failure, celebration

        @ViewBuilder var view: some View {
            switch self {
            case .warning:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.white, Color.brandOrange)
            case .success:
                Image(systemName: "checkmark")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 84, height: 84)
                    .background(Color.successGreen)
                    .clipShape(.circle)
            case .failure:
                Image(systemName: "xmark")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 84, height: 84)
                    .background(Color.failureRed)
                    .clipShape(.circle)
            case .celebration:
                Text("🎉")
                    .font(.system(size: 64))
            }
        }
    }

    let icon: DialogIcon
    let title: String
    let message: String
    var primaryTitle: String
    var primaryAction: () -> Void
    var secondaryTitle: String? = nil
    var secondaryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            icon.view
                .padding(.top, 8)
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.inkPrimary)
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            HStack(spacing: 12) {
                if let secondaryTitle, let secondaryAction {
                    SecondaryButton(title: secondaryTitle, action: secondaryAction)
                }
                PrimaryButton(title: primaryTitle, action: primaryAction)
            }
            .padding(.top, 6)
        }
        .padding(22)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 24))
        .shadow(color: .black.opacity(0.18), radius: 30, y: 10)
        .padding(.horizontal, 24)
    }
}

/// Dimmed backdrop + centered dialog, used via `.dialogOverlay(isPresented:)`.
struct DialogOverlayModifier<Dialog: View>: ViewModifier {
    let isPresented: Bool
    @ViewBuilder let dialog: () -> Dialog

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ZStack {
                        Color.black.opacity(0.45)
                            .ignoresSafeArea()
                        dialog()
                            .transition(.scale(scale: 0.85).combined(with: .opacity))
                    }
                    .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isPresented)
    }
}

extension View {
    func dialogOverlay<Dialog: View>(isPresented: Bool, @ViewBuilder dialog: @escaping () -> Dialog) -> some View {
        modifier(DialogOverlayModifier(isPresented: isPresented, dialog: dialog))
    }
}

/// Full-screen white processing state with a spinning orange arc.
struct ProcessingView: View {
    let title: String
    let message: String
    var onCancel: (() -> Void)? = nil

    @State private var isSpinning: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Circle()
                .trim(from: 0, to: 0.72)
                .stroke(Color.brandOrange, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .frame(width: 74, height: 74)
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
                .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: isSpinning)
                .onAppear { isSpinning = true }
                .padding(.bottom, 34)
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.inkPrimary)
                .padding(.bottom, 10)
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
            if let onCancel {
                TextLinkButton(title: "Cancel", action: onCancel)
                    .padding(.bottom, 28)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

/// Full-screen result state (green check / red X) with title, message and CTAs.
struct ResultView: View {
    let isSuccess: Bool
    let title: String
    let message: String
    var primaryTitle: String
    var primaryAction: () -> Void
    var linkTitle: String? = nil
    var linkAction: (() -> Void)? = nil
    /// Optional extra content between message and buttons (e.g. security renter details card).
    var extraContent: AnyView? = nil

    @State private var iconShown: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            if extraContent == nil { Spacer() } else { Spacer().frame(height: 60) }
            Image(systemName: isSuccess ? "checkmark" : "xmark")
                .font(.system(size: 38, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 92, height: 92)
                .background(isSuccess ? Color.successGreen : Color.failureRed)
                .clipShape(.circle)
                .scaleEffect(iconShown ? 1 : 0.4)
                .opacity(iconShown ? 1 : 0)
                .padding(.bottom, 30)
            Text(title)
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(Color.inkPrimary)
                .padding(.bottom, 10)
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            if let extraContent {
                extraContent
                    .padding(.horizontal, 16)
                    .padding(.top, 26)
            }
            Spacer()
            VStack(spacing: 14) {
                PrimaryButton(title: primaryTitle, action: primaryAction)
                if let linkTitle, let linkAction {
                    TextLinkButton(title: linkTitle, action: linkAction)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                iconShown = true
            }
        }
    }
}


