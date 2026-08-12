import SwiftUI

/// Full booking modal: Review & Pay → processing → success/failure → Access Pass.
struct BookingFlowView: View {
    enum Phase {
        case reviewPay
        case processing
        case success
        case failure
        case accessPass
    }

    /// Checkout payment selection.
    enum PaymentSelection: Hashable {
        case applePay
        case card(UUID)
        case qpay
    }

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let spot: ParkingSpot
    let query: SearchQuery
    @Binding var path: [RenterRoute]

    @State private var phase: Phase = .reviewPay
    @State private var selectedVehicleID: UUID?
    @State private var showAddVehicle: Bool = false
    @State private var showLeaveAlert: Bool = false
    @State private var attemptedOnce: Bool = false
    @State private var createdReservation: Reservation?

    @State private var selectedPayment: PaymentSelection = .applePay
    @State private var showApplePay: Bool = false
    @State private var showQPay: Bool = false
    @State private var showManageCards: Bool = false
    @State private var showAddCard: Bool = false

    private var totalPrice: Double {
        query.totalPrice(for: spot)
    }

    var body: some View {
        Group {
            switch phase {
            case .reviewPay:
                reviewPay
            case .processing:
                ProcessingView(
                    title: "Processing Payment",
                    message: "Hold on while we confirm your payment with the bank."
                )
                .task {
                    try? await Task.sleep(for: .seconds(2))
                    if store.simulateFailures && !attemptedOnce {
                        attemptedOnce = true
                        phase = .failure
                    } else {
                        completeBooking()
                        phase = .success
                    }
                }
            case .success:
                PaymentSuccessView(
                    record: createdReservation?.payment ?? PaymentRecord(
                        method: currentPaymentMethod,
                        amount: totalPrice,
                        paidAtLabel: Date.now.formatted(date: .abbreviated, time: .shortened),
                        reference: "2P-\(String(UUID().uuidString.prefix(8)).uppercased())"
                    ),
                    reservation: createdReservation,
                    onAccessPass: { phase = .accessPass },
                    onViewReservation: { openReservation() }
                )
            case .failure:
                ResultView(
                    isSuccess: false,
                    title: "Payment Failed",
                    message: "Your card was declined. No money was taken. Please try again or use another payment method.",
                    primaryTitle: "Try Again",
                    primaryAction: { phase = .reviewPay },
                    linkTitle: "Cancel",
                    linkAction: { dismiss() }
                )
            case .accessPass:
                if let reservation = createdReservation {
                    AccessPassView(reservation: reservation) {
                        openReservation()
                    }
                }
            }
        }
        .background(Color.white)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: phase)
        .onAppear {
            selectedVehicleID = store.vehicles.first?.id
            if let defaultCard = store.defaultPaymentCard {
                selectedPayment = .card(defaultCard.id)
            }
        }
        .alert("Leave checkout?", isPresented: $showLeaveAlert) {
            Button("Keep Booking", role: .cancel) {}
            Button("Leave", role: .destructive) { dismiss() }
        } message: {
            Text("Your spot isn't reserved yet. If you leave now, this booking won't be completed.")
        }
        .sheet(isPresented: $showAddVehicle) {
            AddVehicleView { vehicle in
                selectedVehicleID = vehicle.id
            }
        }
        .sheet(isPresented: $showApplePay) {
            ApplePaySheetView(total: totalPrice, cardLabel: store.defaultPaymentCard?.displayName ?? "Visa •••• 4242") {
                showApplePay = false
                phase = .processing
            }
            .presentationDetents([.height(400)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showQPay) {
            QPayGatewayView(amount: totalPrice) { success in
                showQPay = false
                if success { phase = .processing }
            }
        }
        .sheet(isPresented: $showManageCards) {
            PaymentMethodsView()
        }
        .sheet(isPresented: $showAddCard) {
            CardFormView(mode: .add) { card in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedPayment = .card(card.id)
                }
            }
        }
    }

    private var isPaymentSelectionValid: Bool {
        if case .card(let id) = selectedPayment {
            return store.paymentCard(id: id) != nil
        }
        return true
    }

    /// Payment method recorded on the reservation's receipt.
    private var currentPaymentMethod: PaymentRecord.Method {
        switch selectedPayment {
        case .applePay:
            return .applePay
        case .card(let id):
            if let card = store.paymentCard(id: id) {
                return .card(card.brand, last4: card.last4)
            }
            return .applePay
        case .qpay:
            return .qpay
        }
    }

    private var payButtonTitle: String {
        switch selectedPayment {
        case .applePay: return "Pay \(Int(totalPrice)) QAR with Apple Pay"
        case .card: return "Pay \(Int(totalPrice)) QAR"
        case .qpay: return "Continue to QPay"
        }
    }

    private func startPayment() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        switch selectedPayment {
        case .applePay: showApplePay = true
        case .card: phase = .processing
        case .qpay: showQPay = true
        }
    }

    private var reviewPay: some View {
        VStack(spacing: 0) {
            TopBar(leadingIcon: "xmark", onLeading: { showLeaveAlert = true })

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Review and Pay")
                        .font(.pageTitle)
                        .foregroundStyle(Color.inkPrimary)

                    totalHeroCard

                    spotSummaryCard

                    HStack {
                        Text("Select Vehicle")
                            .font(.sectionHeader)
                            .foregroundStyle(Color.inkPrimary)
                        Spacer()
                        TextLinkButton(title: "+ Add Vehicle", size: 15) {
                            showAddVehicle = true
                        }
                    }

                    HStack(spacing: 12) {
                        ForEach(store.vehicles) { vehicle in
                            VehicleChip(vehicle: vehicle, isSelected: selectedVehicleID == vehicle.id) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedVehicleID = vehicle.id
                                }
                            }
                        }
                    }

                    paymentSection

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Free Cancellation")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.inkPrimary)
                        Text("Cancel free up to 1h before start time.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.inkSecondary)
                    }

                    HStack(spacing: 0) {
                        Text("By clicking Pay, you agree to our ")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.inkSecondary)
                        Text("Terms of conditions")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.brandOrange)
                            .underline()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }

            PrimaryButton(title: payButtonTitle, isEnabled: selectedVehicleID != nil && isPaymentSelectionValid) {
                startPayment()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }

    /// Payment method picker: Apple Pay, stored cards, and QPay local debit.
    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pay With")
                    .font(.sectionHeader)
                    .foregroundStyle(Color.inkPrimary)
                Spacer()
                TextLinkButton(title: "Manage", size: 15) {
                    showManageCards = true
                }
            }

            VStack(spacing: 10) {
                PaymentOptionRow(
                    icon: .applePay,
                    title: "Apple Pay",
                    subtitle: "Confirm with Face ID",
                    isSelected: selectedPayment == .applePay
                ) {
                    select(.applePay)
                }

                ForEach(store.paymentCards) { card in
                    PaymentOptionRow(
                        icon: .brand(card.brand),
                        title: card.displayName,
                        subtitle: card.isExpired ? "Expired \(card.expiryLabel)" : "Expires \(card.expiryLabel)",
                        badge: card.isDefault ? "Default" : nil,
                        isSelected: selectedPayment == .card(card.id)
                    ) {
                        select(.card(card.id))
                    }
                }

                PaymentOptionRow(
                    icon: .qpay,
                    title: "Local Debit Card",
                    subtitle: "Himyan · NAPS via QPay",
                    isSelected: selectedPayment == .qpay
                ) {
                    select(.qpay)
                }
            }

            Button {
                showAddCard = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15))
                    Text("Add new card")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color.brandOrange)
            }
            .buttonStyle(.plain)
        }
    }

    private func select(_ payment: PaymentSelection) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedPayment = payment
        }
    }

    /// Prominent dates + total card at the top of checkout.
    private var totalHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Dates")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.inkPrimary)
                Spacer()
                TextLinkButton(title: "Change", size: 15) { showLeaveAlert = true }
            }

            IconMetaRow(icon: "calendar", text: query.dateLabel, secondText: query.duration == .daily ? query.endDateLabel : nil)
            if query.duration == .hourly {
                IconMetaRow(icon: "clock", text: query.fromTimeLabel, secondText: query.toTimeLabel)
            }

            Divider().overlay(Color.brandOrange.opacity(0.25))

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Price")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.inkSecondary)
                    PriceText(amount: totalPrice, size: 34)
                }
                Spacer()
                Text("\(query.durationNote)\nIncl. taxes")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.inkSecondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orangeFaint)
        .clipShape(.rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.brandOrange.opacity(0.35), lineWidth: 1)
        )
    }

    private var spotSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                SpotPhoto(name: spot.photos.first ?? "")
                    .frame(width: 88, height: 88)
                    .clipShape(.rect(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 5) {
                    Text(spot.spotCode)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.inkPrimary)
                    Text(spot.buildingName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.inkPrimary)
                    RatingLabel(rating: spot.rating, count: spot.reviewCount)
                }
                Spacer()
            }
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.brandOrange)
                Text(spot.address)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSecondary)
            }
        }
        .padding(14)
        .background(Color.cardGray)
        .clipShape(.rect(cornerRadius: 16))
    }

    private func completeBooking() {
        guard createdReservation == nil else { return }
        let vehicle = store.vehicles.first { $0.id == selectedVehicleID }
        createdReservation = store.createReservation(
            spot: spot, query: query, vehicle: vehicle,
            guestName: store.displayName(for: .renter), guestPhone: store.profilePhone,
            plate: vehicle?.plate ?? "A10232",
            paymentMethod: currentPaymentMethod
        )
    }

    private func openReservation() {
        let id = createdReservation?.id
        dismiss()
        if let id {
            Task {
                try? await Task.sleep(for: .milliseconds(350))
                path.append(.reservationDetails(id))
            }
        }
    }
}
