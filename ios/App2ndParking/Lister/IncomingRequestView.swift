import SwiftUI

/// Incoming long-term rental request: renter info, documents, Accept / Decline with dialogs.
struct IncomingRequestView: View {
    enum Outcome {
        case none
        case accepted
        case declined
    }

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @Binding var path: [ListerRoute]

    @State private var showAcceptDialog: Bool = false
    @State private var showDeclineDialog: Bool = false
    @State private var outcome: Outcome = .none

    private var requestedSpot: ParkingSpot {
        store.spots.first { $0.pricePerDay != nil } ?? store.spots[0]
    }

    var body: some View {
        Group {
            switch outcome {
            case .none:
                requestDetail
            case .accepted:
                ResultView(
                    isSuccess: true,
                    title: "Request Accepted",
                    message: "Jake has been notified. He'll pay the deposit and sign the contract to confirm the long-term rental.",
                    primaryTitle: "Done",
                    primaryAction: { dismiss() }
                )
            case .declined:
                ResultView(
                    isSuccess: false,
                    title: "Request Declined",
                    message: "Jake has been notified that his request was declined. Your spot stays available for other renters.",
                    primaryTitle: "Done",
                    primaryAction: { dismiss() }
                )
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
        .dialogOverlay(isPresented: showAcceptDialog) {
            ConfirmationDialogView(
                icon: .warning,
                title: "Accept request",
                message: "Jake will be asked to pay the deposit and sign the rental contract. Your spot will be reserved for him.",
                primaryTitle: "Accept",
                primaryAction: {
                    showAcceptDialog = false
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { outcome = .accepted }
                },
                secondaryTitle: "Discard",
                secondaryAction: { showAcceptDialog = false }
            )
        }
        .dialogOverlay(isPresented: showDeclineDialog) {
            ConfirmationDialogView(
                icon: .warning,
                title: "Decline request",
                message: "Jake will be notified that his request was declined. This can't be undone.",
                primaryTitle: "Decline",
                primaryAction: {
                    showDeclineDialog = false
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { outcome = .declined }
                },
                secondaryTitle: "Discard",
                secondaryAction: { showDeclineDialog = false }
            )
        }
    }

    private var requestDetail: some View {
        let spot = requestedSpot

        return VStack(spacing: 0) {
            TopBar(leadingIcon: "arrow.left", onLeading: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("New Request")
                        .font(.pageTitle)
                        .foregroundStyle(Color.inkPrimary)

                    HStack(spacing: 14) {
                        AvatarCircle(name: "Jake Morrison", size: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("Jake Morrison")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Color.inkPrimary)
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.brandOrange)
                            }
                            Text("ID & residency verified")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.successGreen)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(Color.cardGray)
                    .clipShape(.rect(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Request Details")
                        InfoCard(rows: [
                            .init(icon: "parkingsign.square", label: "Spot", value: spot.title),
                            .init(icon: "calendar", label: "Duration", value: "Daily · 14 days"),
                            .init(icon: "arrow.right", label: "Dates", value: "01/12/2026 → 15/12/2026"),
                            .init(icon: "banknote", label: "Rent", value: "\(Int(spot.pricePerDay ?? 55)) QAR/day"),
                            .init(icon: "car", label: "Vehicle", value: "VW Passat · A10232")
                        ])
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Documents")
                        HStack(spacing: 10) {
                            documentChip(icon: "person.text.rectangle", label: "QID")
                            documentChip(icon: "doc.text", label: "Tenancy contract")
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Message")
                        Text("Hi! I work in West Bay and need a reliable spot near my office for two weeks. I drive a mid-size sedan and would keep the spot tidy. Thanks!")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.inkSecondary)
                            .lineSpacing(3)
                            .padding(14)
                            .background(Color.cardGray)
                            .clipShape(.rect(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }

            HStack(spacing: 12) {
                SecondaryButton(title: "Decline") { showDeclineDialog = true }
                PrimaryButton(title: "Accept") { showAcceptDialog = true }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func documentChip(icon: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(Color.brandOrange)
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.inkPrimary)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.successGreen)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.cardGray)
        .clipShape(.capsule)
    }
}
