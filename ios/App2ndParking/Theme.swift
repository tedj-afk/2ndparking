import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }

    static let brandOrange = Color(hex: 0xF97316)
    static let brandOrangeDark = Color(hex: 0xEA6206)
    static let orangePale = Color(hex: 0xFDE6D5)
    static let orangeFaint = Color(hex: 0xFEF3EA)
    static let cardGray = Color(hex: 0xF7F7F8)
    static let fieldGray = Color(hex: 0xF4F4F5)
    static let borderGray = Color(hex: 0xE4E4E7)
    static let placeholderGray = Color(hex: 0xD6D6DB)
    static let inkPrimary = Color(hex: 0x18181B)
    static let inkSecondary = Color(hex: 0x6B7280)
    static let inkTertiary = Color(hex: 0x9CA3AF)
    static let successGreen = Color(hex: 0x22C55E)
    static let successPale = Color(hex: 0xDCFCE7)
    static let failureRed = Color(hex: 0xEF4444)
    static let failurePale = Color(hex: 0xFEE2E2)
    static let infoBlue = Color(hex: 0x3B82F6)
    static let infoPale = Color(hex: 0xDBEAFE)
    static let pendingAmber = Color(hex: 0xF59E0B)
    static let starGold = Color(hex: 0xFBBF24)
}

extension Font {
    /// 28-32pt page titles ("My Listings", "Review and Pay")
    static let pageTitle = Font.system(size: 28, weight: .bold)
    static let heroTitle = Font.system(size: 26, weight: .bold)
    /// 17-18pt section headers ("Parking Details")
    static let sectionHeader = Font.system(size: 18, weight: .semibold)
    static let cardTitle = Font.system(size: 16, weight: .semibold)
    static let bodyText = Font.system(size: 15, weight: .regular)
    static let labelText = Font.system(size: 15, weight: .medium)
    static let helperText = Font.system(size: 13, weight: .regular)
    static let priceLarge = Font.system(size: 26, weight: .bold)
}

extension View {
    /// Liquid Glass on iOS 26, frosted material fallback on iOS 18–25.
    @ViewBuilder
    func liquidGlass<S: Shape>(in shape: S, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            self
                .background(shape.fill(.ultraThinMaterial))
                .overlay(shape.stroke(.white.opacity(0.25), lineWidth: 0.5))
        }
    }

    /// Collapses the tab bar on scroll where supported (iOS 26+).
    @ViewBuilder
    func minimizingTabBar() -> some View {
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }
}

/// Formats "40 QAR" price displays: big bold number + small "QAR" suffix.
struct PriceText: View {
    let amount: Double
    var suffix: String = "QAR"
    var trailingNote: String? = nil
    var color: Color = .brandOrange
    var size: CGFloat = 24

    private var amountLabel: String {
        amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", amount)
            : String(format: "%.2f", amount)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(amountLabel)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(color)
            Text(suffix)
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundStyle(color)
            if let trailingNote {
                Text(trailingNote)
                    .font(.helperText)
                    .foregroundStyle(Color.inkSecondary)
            }
        }
    }
}
