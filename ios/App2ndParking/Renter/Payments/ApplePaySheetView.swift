import SwiftUI

/// Simulated Apple Pay payment half-sheet: card summary, total, and a
/// Face ID confirmation animation before authorizing the charge.
struct ApplePaySheetView: View {
    enum AuthPhase {
        case idle
        case authorizing
        case done
    }

    @Environment(\.dismiss) private var dismiss

    let total: Double
    let cardLabel: String
    let onAuthorized: () -> Void

    @State private var authPhase: AuthPhase = .idle

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 2) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 17, weight: .medium))
                    Text("Pay")
                        .font(.system(size: 19, weight: .semibold))
                }
                .foregroundStyle(Color.inkPrimary)

                Spacer()

                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.inkSecondary)
                        .frame(width: 30, height: 30)
                        .background(Color.fieldGray)
                        .clipShape(.circle)
                }
                .disabled(authPhase != .idle)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider()

            VStack(spacing: 0) {
                detailRow(label: "Card", value: cardLabel)
                Divider().padding(.leading, 20)
                detailRow(label: "Account", value: "hello@2ndparking.qa")
                Divider().padding(.leading, 20)
                HStack {
                    Text("Pay 2ndParking")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.inkPrimary)
                    Spacer()
                    PriceText(amount: total, color: .inkPrimary, size: 22)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            Spacer()

            authorizeArea
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
        .background(Color.white)
        .interactiveDismissDisabled(authPhase != .idle)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: authPhase)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color.inkSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.inkPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var authorizeArea: some View {
        switch authPhase {
        case .idle:
            Button {
                authorize()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "faceid")
                        .font(.system(size: 20, weight: .medium))
                    Text("Pay with Face ID")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.black)
                .clipShape(.rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        case .authorizing:
            VStack(spacing: 10) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Color.inkPrimary)
                Text("Confirming with Face ID…")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
        case .done:
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.successGreen)
                    .transition(.scale.combined(with: .opacity))
                Text("Done")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.inkPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
        }
    }

    private func authorize() {
        authPhase = .authorizing
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            authPhase = .done
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            try? await Task.sleep(for: .milliseconds(750))
            onAuthorized()
        }
    }
}
