import SwiftUI

/// Renter reservations grouped by Active / Upcoming / Pending / Past sections.
struct MyReservationsView: View {
    @Environment(AppStore.self) private var store

    @Binding var path: [RenterRoute]

    private let sections: [ReservationStatus] = [.active, .upcoming, .pending, .past]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("My Reservations")
                    .font(.pageTitle)
                    .foregroundStyle(Color.inkPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(sections, id: \.self) { status in
                        let items = store.reservations(with: status)
                        if !items.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Text(status.rawValue)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(Color.inkPrimary)
                                    Circle()
                                        .fill(status.dotColor)
                                        .frame(width: 8, height: 8)
                                }
                                ForEach(items) { reservation in
                                    Button {
                                        if reservation.status == .pending {
                                            path.append(.requestDetails(reservation.id))
                                        } else {
                                            path.append(.reservationDetails(reservation.id))
                                        }
                                    } label: {
                                        ReservationCard(reservation: reservation)
                                    }
                                    .opacity(status == .past ? 0.75 : 1)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 30)
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// Compact reservation card with photo, title and date/time rows.
struct ReservationCard: View {
    let reservation: Reservation
    var trailingName: String? = nil
    var countdown: String? = nil
    /// Security list: prepends the gate state and any delay / check-out countdown.
    var showsSecurityState: Bool = false
    /// Security list reads as a text-only gate log — no spot photo.
    var showsPhoto: Bool = true

    var body: some View {
        var rows: [ListingCard.MetaLine] = []
        if showsSecurityState {
            let state = reservation.securityState
            rows.append(.init(icon: state.icon, text: state.rawValue, tint: state.tint))
            if let delay = reservation.delayLabel {
                rows.append(.init(icon: "exclamationmark.triangle.fill", text: delay, tint: state.tint))
            } else if let left = reservation.checkOutCountdownLabel {
                rows.append(.init(icon: "timer", text: "\(left) to check-out", isBoldOrange: true))
            } else if let out = reservation.checkedOutAtLabel {
                rows.append(.init(icon: "arrow.up.right", text: "Left at \(out)", tint: .inkTertiary))
            }
        } else if let countdown {
            rows.append(.init(icon: "alarm", text: countdown, secondText: nil, isBoldOrange: true))
        }
        rows.append(.init(icon: "calendar", text: reservation.dateLabel, secondText: reservation.endDateLabel))
        if let start = reservation.startTime, let end = reservation.endTime {
            rows.append(.init(icon: "clock", text: start, secondText: end))
        }

        return ListingCard(
            photo: reservation.spot.photos.first ?? "",
            title: reservation.title,
            rows: rows,
            trailingText: trailingName,
            showsPhoto: showsPhoto
        )
    }
}
