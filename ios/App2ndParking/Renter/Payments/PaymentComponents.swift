import SwiftUI

/// Formatting helpers for card entry fields.
enum CardFormatting {
    static func digits(_ text: String) -> String { text.filter(\.isNumber) }

    /// "4111222233334242" → "4111 2222 3333 4242", capped at 16 digits.
    static func formatNumber(_ text: String) -> String {
        let cardDigits = String(digits(text).prefix(16))
        var result = ""
        for (index, character) in cardDigits.enumerated() {
            if index > 0 && index % 4 == 0 { result.append(" ") }
            result.append(character)
        }
        return result
    }

    /// "0827" → "08/27", capped at 4 digits.
    static func formatExpiry(_ text: String) -> String {
        let expiryDigits = String(digits(text).prefix(4))
        guard expiryDigits.count > 2 else { return expiryDigits }
        return "\(expiryDigits.prefix(2))/\(expiryDigits.dropFirst(2))"
    }

    /// Parses "MM/YY" and validates it is a real, non-past expiry.
    static func validExpiry(_ text: String) -> (month: Int, year: Int)? {
        let parts = text.split(separator: "/")
        guard parts.count == 2,
              let month = Int(parts[0]),
              let shortYear = Int(parts[1]),
              (1...12).contains(month) else { return nil }
        let year = 2000 + shortYear
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        guard year > currentYear || (year == currentYear && month >= currentMonth) else { return nil }
        return (month, year)
    }
}

/// Brand logotype drawn with shapes/text — white-on-gradient.
struct CardBrandMark: View {
    let brand: CardBrand
    var compact: Bool = false

    private var circleSize: CGFloat { compact ? 15 : 26 }

    var body: some View {
        switch brand {
        case .visa:
            Text("VISA")
                .font(.system(size: compact ? 10 : 17, weight: .heavy))
                .italic()
                .foregroundStyle(.white)
        case .mastercard:
            ZStack {
                Circle()
                    .fill(Color(hex: 0xEB001B))
                    .frame(width: circleSize, height: circleSize)
                    .offset(x: -circleSize * 0.28)
                Circle()
                    .fill(Color(hex: 0xF79E1B))
                    .opacity(0.9)
                    .frame(width: circleSize, height: circleSize)
                    .offset(x: circleSize * 0.28)
            }
        case .himyan:
            Text("HIMYAN")
                .font(.system(size: compact ? 7.5 : 13, weight: .heavy))
                .foregroundStyle(.white)
        case .naps:
            Text("NAPS")
                .font(.system(size: compact ? 8.5 : 14, weight: .heavy))
                .foregroundStyle(.white)
        }
    }
}

/// Small 46×30 brand tile used in rows and pickers.
struct CardBrandTile: View {
    let brand: CardBrand

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(LinearGradient(colors: brand.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 46, height: 30)
            .overlay(CardBrandMark(brand: brand, compact: true))
    }
}

/// Full-width card artwork used in the wallet screen and card form live preview.
struct PaymentCardVisual: View {
    let brand: CardBrand?
    let numberLine: String
    let holderName: String
    let expiryLabel: String
    var isDefault: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                if let brand {
                    CardBrandMark(brand: brand)
                } else {
                    Text("CARD")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.45))
                }
                Spacer()
                if isDefault {
                    Text("Default")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.22))
                        .clipShape(.capsule)
                }
                Image(systemName: "wave.3.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()

            Text(numberLine)
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer().frame(height: 18)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("CARD HOLDER")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(holderName.isEmpty ? "YOUR NAME" : holderName.uppercased())
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("EXPIRES")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(expiryLabel.isEmpty ? "MM/YY" : expiryLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(height: 190)
        .background(
            LinearGradient(
                colors: brand?.gradientColors ?? [Color(hex: 0x52525B), Color(hex: 0x71717A)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(.white.opacity(0.07))
                .frame(width: 180, height: 180)
                .offset(x: 60, y: -70)
        }
        .clipShape(.rect(cornerRadius: 20))
        .shadow(color: (brand?.gradientColors.first ?? .black).opacity(0.28), radius: 12, y: 6)
    }
}

/// Small 38×25 tile representing how a payment was made (receipt contexts).
struct PaymentMethodTile: View {
    let method: PaymentRecord.Method

    var body: some View {
        switch method {
        case .applePay:
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.black)
                .frame(width: 38, height: 25)
                .overlay(
                    HStack(spacing: 1) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 9, weight: .medium))
                        Text("Pay")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                )
        case .card(let brand, _):
            RoundedRectangle(cornerRadius: 5)
                .fill(LinearGradient(colors: brand.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 38, height: 25)
                .overlay(CardBrandMark(brand: brand, compact: true))
        case .qpay:
            RoundedRectangle(cornerRadius: 5)
                .fill(LinearGradient(colors: [Color(hex: 0x123B5C), Color(hex: 0x1B6CA8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 38, height: 25)
                .overlay(
                    Text("QPay")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.white)
                )
        }
    }
}

/// Receipt-style payment summary card with a dashed tear-off divider.
/// Reused by the post-payment success screen and the reservation detail screen.
struct PaymentReceiptCard: View {
    let record: PaymentRecord
    /// Total booked timeframe (e.g. "4 hours"), shown prominently under the amount.
    var durationLabel: String? = nil
    /// Extra label/value rows inserted between the method and reference rows.
    var extraRows: [(String, String)] = []
    /// Color of the tear-off notches — match the backdrop behind the card.
    var notchColor: Color = .white

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("Amount Paid")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.inkSecondary)
                    .textCase(.uppercase)
                    .kerning(0.6)
                PriceText(amount: record.amount, color: .inkPrimary, size: 36)
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                    Text("Paid · \(record.paidAtLabel)")
                        .font(.system(size: 12.5, weight: .semibold))
                }
                .foregroundStyle(Color.successGreen)
                .padding(.top, 2)

                if let durationLabel {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("\(durationLabel) of parking")
                            .font(.system(size: 13.5, weight: .bold))
                    }
                    .foregroundStyle(Color.brandOrange)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 7)
                    .background(Color.orangePale)
                    .clipShape(.capsule)
                    .padding(.top, 8)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 16)

            notchedDivider

            VStack(spacing: 13) {
                receiptRow(label: "Paid with") {
                    HStack(spacing: 8) {
                        PaymentMethodTile(method: record.method)
                        Text(record.methodTitle)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.inkPrimary)
                    }
                }
                ForEach(Array(extraRows.enumerated()), id: \.offset) { _, row in
                    receiptRow(label: row.0) {
                        Text(row.1)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.inkPrimary)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                    }
                }
                receiptRow(label: "Reference") {
                    Text(record.reference)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.inkPrimary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.borderGray.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.07), radius: 18, y: 8)
    }

    private func receiptRow(label: String, @ViewBuilder value: () -> some View) -> some View {
        HStack(alignment: .center) {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color.inkSecondary)
            Spacer(minLength: 16)
            value()
        }
    }

    /// Dashed tear-off line with side notches, like a paper receipt.
    private var notchedDivider: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(notchColor)
                .frame(width: 18, height: 18)
                .offset(x: -9)
            DashLine()
                .stroke(Color.borderGray, style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                .frame(height: 1.5)
            Circle()
                .fill(notchColor)
                .frame(width: 18, height: 18)
                .offset(x: 9)
        }
        .frame(height: 18)
        .clipped()
    }
}

/// Simple horizontal line shape for the dashed receipt divider.
private struct DashLine: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

/// Selectable payment method row with a radio indicator, used at checkout.
struct PaymentOptionRow: View {
    enum IconStyle {
        case applePay
        case brand(CardBrand)
        case qpay
    }

    let icon: IconStyle
    let title: String
    var subtitle: String? = nil
    var badge: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                iconTile

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.inkPrimary)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundStyle(Color.brandOrange)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.orangePale)
                                .clipShape(.capsule)
                        }
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.inkSecondary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.brandOrange : Color.placeholderGray)
            }
            .padding(12)
            .background(isSelected ? Color.orangeFaint : Color.cardGray)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.brandOrange : Color.clear, lineWidth: 1.5)
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var iconTile: some View {
        switch icon {
        case .applePay:
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black)
                .frame(width: 46, height: 30)
                .overlay(
                    HStack(spacing: 1) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 11, weight: .medium))
                        Text("Pay")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                )
        case .brand(let brand):
            CardBrandTile(brand: brand)
        case .qpay:
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [Color(hex: 0x123B5C), Color(hex: 0x1B6CA8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 46, height: 30)
                .overlay(
                    Text("QPay")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(.white)
                )
        }
    }
}
