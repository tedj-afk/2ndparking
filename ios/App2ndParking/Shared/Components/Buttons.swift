import SwiftUI

/// Full-width orange CTA. Disabled = pale orange fill + orange text.
struct PrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    /// Overrides the orange fill (e.g. red for destructive security actions).
    var background: Color = .brandOrange
    let action: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        } label: {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(isEnabled ? Color.white : Color.brandOrange.opacity(0.65))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(isEnabled ? background : Color.orangePale)
                .clipShape(.rect(cornerRadius: 16))
        }
        .disabled(!isEnabled)
        .scaleEffect(isPressed ? 0.97 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

/// Pale-orange ghost button ("Back", "Discard", "Leave", "Browse More").
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.brandOrange)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.orangePale)
                .clipShape(.rect(cornerRadius: 16))
        }
    }
}

/// Underlined orange text link ("Cancel", "Change", "Edit Listing"...).
struct TextLinkButton: View {
    let title: String
    var color: Color = .brandOrange
    var size: CGFloat = 16
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(color)
                .underline()
        }
    }
}

/// Circular liquid-glass icon button, used floating over photos and maps.
struct GlassCircleButton: View {
    let systemName: String
    var tint: Color = .inkPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .contentShape(.circle)
        }
        .liquidGlass(in: .circle, interactive: true)
    }
}

/// Circular light-gray icon button used in top bars (back chevron, X, "...").
struct CircleIconButton: View {
    let systemName: String
    var tint: Color = .inkPrimary
    var background: Color = .fieldGray
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(background)
                .clipShape(.circle)
        }
    }
}

/// Bottom-right floating action button (orange "+" / QR scan).
struct FloatingActionButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Color.brandOrange)
                .clipShape(.circle)
                .shadow(color: Color.brandOrange.opacity(0.35), radius: 12, y: 6)
        }
    }
}

/// Custom top bar: back/close button, optional centered title + subtitle, trailing button.
struct TopBar: View {
    var leadingIcon: String? = "chevron.left"
    var onLeading: (() -> Void)? = nil
    var title: String? = nil
    var subtitle: String? = nil
    var subtitleIsLink: Bool = false
    var onSubtitle: (() -> Void)? = nil
    var trailingIcon: String? = nil
    var onTrailing: (() -> Void)? = nil

    var body: some View {
        ZStack {
            if title != nil || subtitle != nil {
                VStack(spacing: 2) {
                    if let title {
                        Text(title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.inkPrimary)
                            .lineLimit(1)
                    }
                    if let subtitle {
                        if subtitleIsLink {
                            Button(action: { onSubtitle?() }) {
                                Text(subtitle)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.brandOrange)
                                    .underline()
                            }
                        } else {
                            Text(subtitle)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.inkSecondary)
                        }
                    }
                }
                .padding(.horizontal, 56)
            }
            HStack {
                if let leadingIcon, let onLeading {
                    CircleIconButton(systemName: leadingIcon, action: onLeading)
                }
                Spacer()
                if let trailingIcon, let onTrailing {
                    CircleIconButton(systemName: trailingIcon, action: onTrailing)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

/// "2nd [P]" brand lockup used on the renter home header.
struct BrandLogo: View {
    var body: some View {
        HStack(spacing: 5) {
            Text("2nd")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(Color.inkPrimary)
            Text("P")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(Color.brandOrange)
                .frame(width: 42, height: 42)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.brandOrange, lineWidth: 3.5)
                )
        }
    }
}
