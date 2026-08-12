import SwiftUI

/// Reservations for one listing, filtered by status tabs.
struct ListerReservationsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let spotID: UUID
    @Binding var path: [ListerRoute]

    @State private var filter: String = "All"

    private let filters = ["All", "Active", "Upcoming", "Past", "Cancelled"]

    private var filtered: [Reservation] {
        let base = store.reservations.filter { $0.spot.buildingName == store.spot(id: spotID)?.buildingName }
        let scoped = base.isEmpty ? store.reservations : base
        switch filter {
        case "Active": return scoped.filter { $0.status == .active }
        case "Upcoming": return scoped.filter { $0.status == .upcoming }
        case "Past": return scoped.filter { $0.status == .past }
        case "Cancelled": return scoped.filter { $0.status == .cancelled }
        default: return scoped
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(leadingIcon: "arrow.left", onLeading: { dismiss() })

            HStack {
                Text("Reservations")
                    .font(.pageTitle)
                    .foregroundStyle(Color.inkPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            FilterTabs(options: filters, selection: $filter)
                .padding(.bottom, 12)

            ScrollView {
                VStack(spacing: 14) {
                    ForEach(filtered) { reservation in
                        Button {
                            path.append(.reservationDetail(reservation.id))
                        } label: {
                            ReservationCard(reservation: reservation, trailingName: reservation.guestName)
                        }
                        .opacity(reservation.status == .past || reservation.status == .cancelled ? 0.7 : 1)
                    }
                    if filtered.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "ticket")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.placeholderGray)
                            Text("No reservations in this filter")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.inkSecondary)
                        }
                        .padding(.top, 70)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
    }
}
