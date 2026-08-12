import SwiftUI

/// Lister home: "My Listings" with filter tabs and add-listing FAB.
struct MyListingsView: View {
    @Environment(AppStore.self) private var store

    @Binding var path: [ListerRoute]
    @Binding var showAddListing: Bool

    @State private var filter: String = "All"

    private let filters = ["All", "Free", "Reserved", "Archived"]

    private var filtered: [ParkingSpot] {
        switch filter {
        case "Free": return store.spots.filter { $0.status == .free || $0.status == .live }
        case "Reserved": return store.spots.filter { $0.status == .reserved }
        case "Archived": return store.spots.filter { $0.status == .archived }
        default: return store.spots
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                HStack {
                    Text("My Listings")
                        .font(.pageTitle)
                        .foregroundStyle(Color.inkPrimary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                FilterTabs(options: filters, selection: $filter)
                    .padding(.bottom, 12)

                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(filtered) { spot in
                            Button {
                                path.append(.listingDetail(spot.id))
                            } label: {
                                ListingCard(
                                    photo: spot.photos.first ?? "",
                                    title: "\(spot.spotCode) \(spot.buildingName)",
                                    rows: listingRows(for: spot)
                                )
                                .opacity(spot.status == .archived ? 0.6 : 1)
                            }
                        }
                        if filtered.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "parkingsign.square")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color.placeholderGray)
                                Text("No listings here yet")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.inkSecondary)
                            }
                            .padding(.top, 70)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }

            FloatingActionButton(systemName: "plus") {
                showAddListing = true
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func listingRows(for spot: ParkingSpot) -> [ListingCard.MetaLine] {
        var rows: [ListingCard.MetaLine] = []
        if spot.status == .reserved {
            rows.append(.init(icon: nil, text: spot.primaryDuration.rawValue, isBoldOrange: true))
            rows.append(.init(icon: "calendar", text: "05/12/2026"))
            rows.append(.init(icon: "clock", text: "11:00 AM", secondText: "3:00 PM"))
        } else {
            let prices: [String] = [
                spot.pricePerHour.map { "\(Int($0)) QAR/h" },
                spot.pricePerDay.map { "\(Int($0)) QAR/day" }
            ].compactMap { $0 }
            rows.append(.init(icon: nil, text: spot.status.rawValue, textColor: spot.status == .archived ? .inkTertiary : .successGreen))
            rows.append(.init(icon: "banknote", text: prices.joined(separator: " · ")))
            if spot.schedule.isPaused {
                rows.append(.init(icon: "pause.circle", text: "Bookings paused", tint: .pendingAmber))
            } else {
                rows.append(.init(icon: "clock", text: spot.schedule.compactSummary))
            }
            if let blocked = spot.schedule.blockedSummary {
                rows.append(.init(icon: "calendar.badge.minus", text: blocked, tint: .inkTertiary))
            }
        }
        return rows
    }
}
