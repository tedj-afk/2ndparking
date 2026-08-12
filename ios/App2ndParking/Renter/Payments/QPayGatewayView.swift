import SwiftUI

/// Simulated QPay payment gateway for Qatari debit cards (Himyan / NAPS).
/// Mirrors the hosted-page flow: merchant summary → debit card + PIN → bank
/// authorization → redirect back to the app.
struct QPayGatewayView: View {
    enum GatewayPhase {
        case form
        case processing
        case approved
    }

    let amount: Double
    let onResult: (Bool) -> Void

    @State private var gatewayPhase: GatewayPhase = .form
    @State private var scheme: CardBrand = .himyan
    @State private var numberText: String = ""
    @State private var expiryText: String = ""
    @State private var holderName: String = ""
    @State private var pin: String = ""

    private static let qpayNavy = Color(hex: 0x123B5C)
    private static let qpayBlue = Color(hex: 0x1B6CA8)
    private static let pageGray = Color(hex: 0xEEF2F6)

    private var canPay: Bool {
        CardFormatting.digits(numberText).count == 16
            && CardFormatting.validExpiry(expiryText) != nil
            && holderName.trimmingCharacters(in: .whitespaces).count >= 3
            && pin.count == 4
    }

    var body: some View {
        VStack(spacing: 0) {
            gatewayHeader

            switch gatewayPhase {
            case .form:
                form
            case .processing, .approved:
                statusView
            }
        }
        .background(Self.pageGray)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: gatewayPhase)
        .onChange(of: numberText) { _, newValue in
            let formatted = CardFormatting.formatNumber(newValue)
            if formatted != newValue { numberText = formatted }
            // Auto-highlight the detected local scheme.
            if let detected = CardBrand.detect(fromDigits: CardFormatting.digits(numberText)), detected.isLocalDebit {
                scheme = detected
            }
        }
        .onChange(of: expiryText) { oldValue, newValue in
            guard newValue.count > oldValue.count || !newValue.contains("/") else { return }
            let formatted = CardFormatting.formatExpiry(newValue)
            if formatted != newValue { expiryText = formatted }
        }
        .onChange(of: pin) { _, newValue in
            let digits = String(CardFormatting.digits(newValue).prefix(4))
            if digits != newValue { pin = digits }
        }
    }

    private var gatewayHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
            VStack(alignment: .leading, spacing: 1) {
                Text("QPay")
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(.white)
                Text("Qatar Payment Gateway")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Button {
                onResult(false)
            } label: {
                Text("Cancel")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.15))
                    .clipShape(.capsule)
            }
            .disabled(gatewayPhase != .form)
            .opacity(gatewayPhase == .form ? 1 : 0.4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(
            LinearGradient(colors: [Self.qpayNavy, Self.qpayBlue], startPoint: .leading, endPoint: .trailing)
        )
    }

    // MARK: - Form

    private var form: some View {
        ScrollView {
            VStack(spacing: 16) {
                merchantCard

                VStack(alignment: .leading, spacing: 14) {
                    Text("Debit Card Details")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Self.qpayNavy)

                    HStack(spacing: 10) {
                        schemeChip(.himyan)
                        schemeChip(.naps)
                        Spacer()
                    }

                    gatewayField(label: "Card Number", placeholder: "6xxx xxxx xxxx xxxx", text: $numberText, keyboard: .numberPad)

                    HStack(spacing: 12) {
                        gatewayField(label: "Expiry", placeholder: "MM/YY", text: $expiryText, keyboard: .numberPad)
                        gatewayField(label: "PIN", placeholder: "••••", text: $pin, keyboard: .numberPad, isSecure: true)
                    }

                    gatewayField(label: "Cardholder Name", placeholder: "Name as printed on card", text: $holderName, keyboard: .default)
                }
                .padding(16)
                .background(Color.white)
                .clipShape(.rect(cornerRadius: 16))

                Button {
                    pay()
                } label: {
                    Text("Pay \(Int(amount)) QAR")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(colors: scheme.gradientColors, startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(.rect(cornerRadius: 14))
                        .opacity(canPay ? 1 : 0.4)
                }
                .buttonStyle(.plain)
                .disabled(!canPay)

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 12))
                    Text("Secured by NAPS · Regulated by Qatar Central Bank")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color.inkSecondary)
                .frame(maxWidth: .infinity)
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var merchantCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Merchant")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSecondary)
                Spacer()
                Text("2ndParking W.L.L")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.inkPrimary)
            }
            HStack {
                Text("Order Reference")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSecondary)
                Spacer()
                Text("QP-\(String(UUID().uuidString.prefix(8)))")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.inkPrimary)
            }
            Divider()
            HStack(alignment: .firstTextBaseline) {
                Text("Amount")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.inkSecondary)
                Spacer()
                PriceText(amount: amount, color: Self.qpayNavy, size: 26)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 16))
    }

    private func schemeChip(_ brand: CardBrand) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                scheme = brand
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 8) {
                CardBrandTile(brand: brand)
                Text(brand.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.inkPrimary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(scheme == brand ? brand.gradientColors[0].opacity(0.1) : Self.pageGray)
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(scheme == brand ? brand.gradientColors[0] : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func gatewayField(label: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.inkSecondary)
            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .font(.system(size: 15))
            .keyboardType(keyboard)
            .autocorrectionDisabled()
            .padding(.horizontal, 13)
            .frame(height: 48)
            .background(Self.pageGray)
            .clipShape(.rect(cornerRadius: 10))
        }
    }

    // MARK: - Status

    private var statusView: some View {
        VStack(spacing: 16) {
            Spacer()
            if gatewayPhase == .processing {
                ProgressView()
                    .controlSize(.large)
                    .tint(Self.qpayNavy)
                Text("Contacting your bank…")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Self.qpayNavy)
                Text("Do not close this page.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSecondary)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.successGreen)
                    .transition(.scale.combined(with: .opacity))
                Text("Payment Approved")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Self.qpayNavy)
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Redirecting you back to 2ndParking…")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkSecondary)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func pay() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        gatewayPhase = .processing
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            gatewayPhase = .approved
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            try? await Task.sleep(for: .seconds(1.2))
            onResult(true)
        }
    }
}
