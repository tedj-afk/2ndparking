import SwiftUI

/// Long-term request detail with status stepper: Requested → Accepted → Pay deposit → Sign.
struct RequestDetailsView: View {
    enum Phase {
        case detail
        case processingPayment
        case paymentSuccess
        case signing
    }

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let reservationID: UUID
    @Binding var path: [RenterRoute]

    @State private var phase: Phase = .detail
    @State private var showSignedDialog: Bool = false

    var body: some View {
        Group {
            if let reservation = store.reservation(id: reservationID) {
                content(reservation: reservation)
            } else {
                Color.white.onAppear { dismiss() }
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func content(reservation: Reservation) -> some View {
        switch phase {
        case .detail:
            detail(reservation: reservation)
        case .processingPayment:
            ProcessingView(
                title: "Processing Payment",
                message: "Hold on while we confirm your deposit payment."
            )
            .task {
                try? await Task.sleep(for: .seconds(2))
                store.advanceStage(id: reservationID, to: .sign)
                phase = .paymentSuccess
            }
        case .paymentSuccess:
            ResultView(
                isSuccess: true,
                title: "Payment Successful",
                message: "Your payment has been received. You can now review and sign the rental contract.",
                primaryTitle: "Review & Sign Contract",
                primaryAction: { phase = .signing },
                linkTitle: "Later",
                linkAction: { phase = .detail }
            )
        case .signing:
            ContractSigningView(reservation: reservation) {
                store.advanceStage(id: reservationID, to: .completed)
                phase = .detail
                showSignedDialog = true
            } onClose: {
                phase = .detail
            }
        }
    }

    private func detail(reservation: Reservation) -> some View {
        let stage = reservation.stage
        let stepperIndex = min(stage.rawValue, 3)

        return VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ImageCarousel(photos: reservation.spot.photos, onBack: { dismiss() }, onMore: {})

                    VStack(alignment: .leading, spacing: 12) {
                        Text(reservation.title)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Color.inkPrimary)

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.brandOrange)
                            Text(reservation.spot.address)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.inkSecondary)
                        }

                        IconMetaRow(icon: "calendar", text: reservation.dateLabel, secondText: reservation.endDateLabel)

                        PriceText(amount: reservation.totalPrice, trailingNote: nil, size: 24)
                            .overlay(alignment: .trailingLastTextBaseline) {
                                Text("")
                            }
                        HStack(spacing: 6) {
                            Text("\(reservation.duration.rawValue) · Long-term request")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.brandOrange)
                            Spacer()
                        }
                        .padding(.top, -12)

                        HostRow(
                            name: reservation.spot.listerName,
                            verified: reservation.spot.listerVerified,
                            rating: reservation.spot.rating,
                            reviewCount: reservation.spot.reviewCount
                        )

                        Text(reservation.spot.description)
                            .font(.system(size: 15))
                            .foregroundStyle(Color.inkSecondary)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, 16)

                    StatusStepper(
                        stages: ["Requested", "Accepted", "Pay deposit", "Sign"],
                        currentIndex: stepperIndex,
                        pendingLabelOverride: stage == .requested ? "Pending" : nil
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    if stage == .completed || reservation.isContractSigned {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.successGreen)
                            Text("Contract signed — your long-term rental is confirmed")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.inkPrimary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.successPale)
                        .clipShape(.rect(cornerRadius: 14))
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 24)
            }
            .ignoresSafeArea(edges: .top)

            bottomAction(stage: stage)
        }
        .dialogOverlay(isPresented: showSignedDialog) {
            ConfirmationDialogView(
                icon: .celebration,
                title: "You're in!",
                message: "The contract is signed and your spot is reserved. Your access pass will activate on the start date.",
                primaryTitle: "Done",
                primaryAction: { showSignedDialog = false }
            )
        }
    }

    @ViewBuilder
    private func bottomAction(stage: RequestStage) -> some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.borderGray.opacity(0.5))
            Group {
                switch stage {
                case .requested:
                    PrimaryButton(title: "Pending Lister Approval", isEnabled: false) {}
                case .accepted, .payDeposit:
                    PrimaryButton(title: "Pay Deposit & Sign") {
                        phase = .processingPayment
                    }
                case .sign:
                    PrimaryButton(title: "Sign Contract") {
                        phase = .signing
                    }
                case .completed:
                    PrimaryButton(title: "View My Reservations") {
                        path = [.myReservations]
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white)
    }
}
