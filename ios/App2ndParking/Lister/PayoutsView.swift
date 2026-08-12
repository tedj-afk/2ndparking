import SwiftUI

/// Payout settings: IBAN form, next payout summary, commission breakdown, history.
struct PayoutsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var isTabRoot: Bool = false

    @State private var iban: String = ""
    @State private var showSavedDialog: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            if isTabRoot {
                Spacer().frame(height: 18)
            } else {
                TopBar(leadingIcon: "arrow.left", onLeading: { dismiss() })
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Payouts")
                        .font(.pageTitle)
                        .foregroundStyle(Color.inkPrimary)

                    nextPayoutCard

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Bank Account")
                        if store.ibanConnected {
                            HStack(spacing: 12) {
                                Image(systemName: "building.columns")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.brandOrange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("QNB · \(maskedIban)")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Color.inkPrimary)
                                    Text("Payouts every 1st of the month")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.inkSecondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.successGreen)
                            }
                            .padding(14)
                            .background(Color.cardGray)
                            .clipShape(.rect(cornerRadius: 14))
                            TextLinkButton(title: "Change bank account", size: 14) {
                                store.ibanConnected = false
                                iban = ""
                            }
                        } else {
                            FormField(label: "IBAN", placeholder: "QA58 QNBA 0000 0000 0000 0000 0000 0", text: $iban)
                            PrimaryButton(title: "Save Bank Account", isEnabled: iban.count >= 8) {
                                store.ibanValue = iban
                                store.ibanConnected = true
                                showSavedDialog = true
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "How payouts work")
                        InfoCard(rows: [
                            .init(icon: "banknote", label: "Bookings this month", value: "630 QAR"),
                            .init(icon: "percent", label: "2ndParking fee (5%)", value: "− 31.50 QAR"),
                            .init(icon: "arrow.down.circle", label: "You receive", value: "598.50 QAR")
                        ])
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Payout History")
                        VStack(spacing: 10) {
                            ForEach(store.payouts) { payout in
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(String(format: "%.2f QAR", payout.amount))
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(Color.inkPrimary)
                                        Text(payout.dateLabel)
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color.inkSecondary)
                                    }
                                    Spacer()
                                    StatusPill(text: payout.status, dotColor: .successGreen, background: .successPale)
                                }
                                .padding(14)
                                .background(Color.cardGray)
                                .clipShape(.rect(cornerRadius: 14))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
        .dialogOverlay(isPresented: showSavedDialog) {
            ConfirmationDialogView(
                icon: .success,
                title: "Bank Account Saved",
                message: "Your payouts will be sent to this account on the 1st of every month.",
                primaryTitle: "Done",
                primaryAction: { showSavedDialog = false }
            )
        }
    }

    private var maskedIban: String {
        let value = store.ibanValue.replacingOccurrences(of: " ", with: "")
        guard value.count > 4 else { return "••••" }
        return "•••• \(value.suffix(4))"
    }

    private var nextPayoutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Next Payout")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("598.50")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                Text("QAR")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
            }
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .medium))
                Text("Arriving 01/09/2026")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.95))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.brandOrange)
        .clipShape(.rect(cornerRadius: 20))
    }
}
