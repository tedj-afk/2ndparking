import SwiftUI

enum SecurityRoute: Hashable {
    case reservationDetail(UUID)
    case notifications
    case profile
}

enum SecurityTab: Hashable {
    case checkIns
    case notifications
    case profile
}

/// Security experience: bottom tab bar with check-ins + QR scan flow.
struct SecurityRootView: View {
    @Environment(AppStore.self) private var store

    @State private var selectedTab: SecurityTab = .checkIns
    @State private var checkInsPath: [SecurityRoute] = []
    @State private var notificationsPath: [SecurityRoute] = []
    @State private var showScanner: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Check-ins", systemImage: "qrcode.viewfinder", value: SecurityTab.checkIns) {
                NavigationStack(path: $checkInsPath) {
                    CheckInsView(path: $checkInsPath, showScanner: $showScanner)
                        .navigationDestination(for: SecurityRoute.self) { route in
                            destination(for: route)
                        }
                }
            }

            Tab("Notifications", systemImage: "bell", value: SecurityTab.notifications) {
                NavigationStack(path: $notificationsPath) {
                    NotificationsView(role: .security, isTabRoot: true, onOpenReservation: { id in
                        notificationsPath.append(.reservationDetail(id))
                    })
                    .navigationDestination(for: SecurityRoute.self) { route in
                        destination(for: route)
                    }
                }
            }
            .badge(store.unreadCount(for: .security))

            Tab("Profile", systemImage: "person.crop.circle", value: SecurityTab.profile) {
                NavigationStack {
                    ProfileView(role: .security, isTabRoot: true)
                }
            }
        }
        .tint(Color.brandOrange)
        .minimizingTabBar()
    }

    @ViewBuilder
    private func destination(for route: SecurityRoute) -> some View {
        switch route {
        case .reservationDetail(let id):
            SecurityReservationContainer(reservationID: id)
        case .notifications:
            NotificationsView(role: .security)
        case .profile:
            ProfileView(role: .security)
        }
    }
}

/// Wraps the shared reservation detail with the security check-in flow.
struct SecurityReservationContainer: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let reservationID: UUID

    @State private var pendingMode: GateMode? = nil
    @State private var completedMode: GateMode? = nil

    var body: some View {
        Group {
            if let mode = pendingMode {
                ProcessingView(
                    title: mode == .checkIn ? "Processing Verification" : "Processing Check-Out",
                    message: mode == .checkIn
                        ? "Confirming the reservation and access permissions."
                        : "Closing the stay and releasing the spot."
                )
                .task {
                    try? await Task.sleep(for: .seconds(1.8))
                    switch mode {
                    case .checkIn: store.checkIn(reservationID: reservationID)
                    case .checkOut: store.checkOut(reservationID: reservationID)
                    }
                    pendingMode = nil
                    completedMode = mode
                }
            } else if let mode = completedMode, let reservation = store.reservation(id: reservationID) {
                GateResultView(reservation: reservation, mode: mode) {
                    dismiss()
                }
            } else {
                ReservationDetailView(
                    reservationID: reservationID,
                    role: .security,
                    onCheckIn: { pendingMode = .checkIn },
                    onCheckOut: { pendingMode = .checkOut }
                )
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: pendingMode)
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// Which gate action the officer is performing.
enum GateMode: Hashable {
    case checkIn
    case checkOut
}

/// Green check + stay summary shown after a successful check-in or check-out.
struct GateResultView: View {
    let reservation: Reservation
    let mode: GateMode
    let onDone: () -> Void

    private var isLate: Bool { reservation.overstayMinutes > 0 }

    private var title: String {
        switch mode {
        case .checkIn: return "Check-In Completed"
        case .checkOut: return isLate ? "Checked Out · Overstay" : "Check-Out Completed"
        }
    }

    private var message: String {
        switch mode {
        case .checkIn:
            return "Reservation confirmed. The guest is authorized to enter."
        case .checkOut:
            if let fee = reservation.overstayFee {
                return "The vehicle left \(Reservation.minutesLabel(reservation.overstayMinutes)) past the booked window. A \(Int(fee)) QAR overstay fee was added."
            }
            return "The vehicle has left and the spot is free again."
        }
    }

    private var rows: [InfoCard.DetailRowData] {
        var rows: [InfoCard.DetailRowData] = [
            .init(label: "Visitor Name", value: reservation.guestName),
            .init(label: "Plate Number", value: reservation.plateNumber),
            .init(label: "Spot Label", value: reservation.spot.spotCode),
            .init(
                label: "Booked Window",
                value: "\(reservation.startTime ?? reservation.dateLabel) → \(reservation.endTime ?? reservation.endDateLabel ?? "")"
            ),
            .init(label: "Check-in Time", value: reservation.checkedInAtLabel ?? "—")
        ]
        if mode == .checkOut {
            rows.append(.init(label: "Check-out Time", value: reservation.checkedOutAtLabel ?? "—"))
            rows.append(.init(label: "Total Inside", value: reservation.bookedDurationLabel))
            if let fee = reservation.overstayFee {
                rows.append(.init(label: "Overstay Fee", value: "\(Int(fee)) QAR"))
            }
        } else {
            rows.append(.init(label: "Reserved By", value: reservation.residentName ?? "—"))
        }
        return rows
    }

    var body: some View {
        ResultView(
            isSuccess: true,
            title: title,
            message: message,
            primaryTitle: "Done",
            primaryAction: onDone,
            extraContent: AnyView(
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: mode == .checkIn ? "Reservation Details" : "Stay Summary")
                    InfoCard(rows: rows)
                }
            )
        )
    }
}
