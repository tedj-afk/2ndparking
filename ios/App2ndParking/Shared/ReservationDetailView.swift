import SwiftUI

/// Reservation detail shared by renter, lister and security (role changes sections + actions).
struct ReservationDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let reservationID: UUID
    let role: AppRole
    var path: Binding<[RenterRoute]>? = nil
    /// Security: called when Check-In is tapped.
    var onCheckIn: (() -> Void)? = nil
    /// Security: called when Check-Out is tapped.
    var onCheckOut: (() -> Void)? = nil

    @State private var showCancelDialog: Bool = false
    @State private var showAccessPass: Bool = false
    @State private var receiptShown: Bool = false

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

    private func content(reservation: Reservation) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if role == .security {
                        securityHeader(reservation: reservation)
                    } else {
                        ImageCarousel(photos: reservation.spot.photos, onBack: { dismiss() }, onMore: {})
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            Text(reservation.spot.spotCode)
                                .font(.system(size: 27, weight: .bold))
                                .foregroundStyle(Color.inkPrimary)
                            Spacer()
                            StatusPill(
                                text: reservation.status.rawValue,
                                dotColor: reservation.status.dotColor,
                                background: reservation.status == .active ? Color.successPale : Color.fieldGray
                            )
                        }
                        Text(reservation.spot.buildingName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.inkPrimary)
                            .padding(.top, -8)

                        HStack(alignment: .top, spacing: 8) {
                            Text(reservation.spot.address)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.inkSecondary)
                            Spacer()
                            if role != .security {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 17))
                                    .foregroundStyle(Color.brandOrange)
                                    .frame(width: 42, height: 42)
                                    .background(Color.orangePale)
                                    .clipShape(.circle)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, role == .security ? -4 : 0)

                    if role == .security {
                        VStack(spacing: 12) {
                            CheckInScheduleCard(reservation: reservation)
                            if reservation.securityState.needsAttention || reservation.securityState == .checkedOutLate {
                                CheckDelayBanner(reservation: reservation)
                            }
                        }
                        .padding(.horizontal, 16)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Date & Time")
                            HStack {
                                IconMetaRow(icon: "calendar", text: reservation.dateLabel, secondText: reservation.endDateLabel)
                                Spacer()
                                if let start = reservation.startTime, let end = reservation.endTime {
                                    IconMetaRow(icon: "clock", text: start, secondText: end)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    if role != .renter {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Resident Information")
                            InfoCard(rows: [
                                .init(icon: "person", label: "Full Name", value: reservation.residentName ?? "—"),
                                .init(icon: "building.2", label: "Tower", value: reservation.spot.buildingName),
                                .init(icon: "number", label: "Unit Number", value: reservation.unitNumber ?? "—"),
                                .init(icon: "phone", label: "Mobile Number", value: "+974 5088 3202")
                            ])
                        }
                        .padding(.horizontal, 16)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Vehicle Information")
                        InfoCard(rows: [
                            .init(icon: "car", label: "Brand", value: reservation.vehicleBrand),
                            .init(icon: "shippingbox", label: "Model", value: reservation.vehicleModel),
                            .init(icon: "number", label: "Plate Number", value: reservation.plateNumber),
                            .init(icon: "person", label: "Guest Name", value: reservation.guestName),
                            .init(icon: "phone", label: "Mobile Number", value: reservation.guestPhone)
                        ])
                    }
                    .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Parking Details")
                        ParkingDetailsCard(spot: reservation.spot)
                    }
                    .padding(.horizontal, 16)

                    if role == .renter, let payment = reservation.payment {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Payment")
                            PaymentReceiptCard(
                                record: payment,
                                durationLabel: reservation.bookedDurationLabel,
                                notchColor: .white
                            )
                            .opacity(receiptShown ? 1 : 0)
                            .offset(y: receiptShown ? 0 : 26)
                            .scaleEffect(receiptShown ? 1 : 0.96)
                            .onAppear {
                                guard !receiptShown else { return }
                                withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.15)) {
                                    receiptShown = true
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    if role == .renter {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Access Instructions")
                            AccessInstructionsList(instructions: reservation.spot.accessInstructions)
                        }
                        .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Cancellation Policy")
                            Text(reservation.spot.cancellationPolicy)
                                .font(.system(size: 15))
                                .foregroundStyle(Color.inkSecondary)
                                .lineSpacing(3)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 24)
            }
            .ignoresSafeArea(edges: .top)

            bottomActions(reservation: reservation)
        }
        .dialogOverlay(isPresented: showCancelDialog) {
            ConfirmationDialogView(
                icon: .warning,
                title: "Cancel Reservation",
                message: "Are you sure you want to cancel this reservation? Free cancellation applies up to 1 hour before the start time.",
                primaryTitle: "Cancel It",
                primaryAction: {
                    showCancelDialog = false
                    store.cancelReservation(id: reservationID)
                    dismiss()
                },
                secondaryTitle: "Keep It",
                secondaryAction: { showCancelDialog = false }
            )
        }
        .fullScreenCover(isPresented: $showAccessPass) {
            if let current = store.reservation(id: reservationID) {
                AccessPassView(reservation: current)
            }
        }
    }

    /// Security sees a text-only gate record — photos of the spot aren't useful at the barrier.
    private func securityHeader(reservation: Reservation) -> some View {
        HStack(spacing: 12) {
            CircleIconButton(systemName: "chevron.left") { dismiss() }

            VStack(alignment: .leading, spacing: 2) {
                Text("Gate Record")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.inkPrimary)
                Text(reservation.plateNumber)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.inkSecondary)
            }

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Image(systemName: reservation.securityState.icon)
                    .font(.system(size: 12, weight: .bold))
                Text(reservation.securityState.rawValue)
                    .font(.system(size: 12.5, weight: .bold))
            }
            .foregroundStyle(reservation.securityState.tint)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(reservation.securityState.tint.opacity(0.13))
            .clipShape(.capsule)
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func bottomActions(reservation: Reservation) -> some View {
        VStack(spacing: 12) {
            Divider().overlay(Color.borderGray.opacity(0.5))
            switch role {
            case .renter:
                if reservation.status == .active || reservation.status == .upcoming {
                    PrimaryButton(title: "Access Pass") { showAccessPass = true }
                        .padding(.horizontal, 16)
                    if reservation.status == .upcoming {
                        TextLinkButton(title: "Cancel Reservation", color: .failureRed) {
                            showCancelDialog = true
                        }
                    }
                }
            case .lister:
                EmptyView()
            case .security:
                if reservation.canCheckIn {
                    PrimaryButton(title: reservation.securityState == .lateArrival ? "Check-In (late arrival)" : "Check-In") {
                        onCheckIn?()
                    }
                    .padding(.horizontal, 16)
                } else if reservation.canCheckOut {
                    PrimaryButton(
                        title: reservation.securityState == .overstay ? "Check-Out & charge overstay" : "Check-Out",
                        background: reservation.securityState == .overstay ? .failureRed : .brandOrange
                    ) {
                        onCheckOut?()
                    }
                    .padding(.horizontal, 16)
                } else if let leftAt = reservation.checkedOutAtLabel {
                    HStack(spacing: 8) {
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 14, weight: .bold))
                        Text("Checked out at \(leftAt)")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Color.inkSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.fieldGray)
                    .clipShape(.rect(cornerRadius: 14))
                    .padding(.horizontal, 16)
                }
                TextLinkButton(title: "Report Issue", color: .failureRed) {}
            }
        }
        .padding(.bottom, 10)
        .background(Color.white)
    }
}
