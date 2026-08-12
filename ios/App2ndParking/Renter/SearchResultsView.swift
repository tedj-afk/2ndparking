import SwiftUI

/// How search results can be ordered from the sort half sheet.
enum SpotSortOption: String, CaseIterable, Identifiable {
    case recommended = "Recommended"
    case priceLowToHigh = "Price: low to high"
    case priceHighToLow = "Price: high to low"
    case nearest = "Nearest first"
    case topRated = "Top rated"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .recommended: return "sparkles"
        case .priceLowToHigh: return "arrow.down.circle"
        case .priceHighToLow: return "arrow.up.circle"
        case .nearest: return "location"
        case .topRated: return "star"
        }
    }
}

/// List of matching spots with "Modify Search" subtitle header and sort sheet.
struct SearchResultsView: View {
    @Environment(AppStore.self) private var store
    @Environment(LocationService.self) private var locationService
    @Environment(\.dismiss) private var dismiss

    let query: SearchQuery
    @Binding var path: [RenterRoute]

    @State private var sortOption: SpotSortOption = .recommended
    @State private var showSortSheet: Bool = false
    @State private var showsUnavailable: Bool = false

    /// Spots in the area the owner keeps closed for the requested window.
    private var unavailable: [ParkingSpot] {
        store.unavailableResults(for: query)
    }

    private var results: [ParkingSpot] {
        let base = store.searchResults(for: query)
        switch sortOption {
        case .recommended:
            return base
        case .priceLowToHigh:
            return base.sorted { query.totalPrice(for: $0) < query.totalPrice(for: $1) }
        case .priceHighToLow:
            return base.sorted { query.totalPrice(for: $0) > query.totalPrice(for: $1) }
        case .nearest:
            return base.sorted {
                locationService.distanceKm(latitude: $0.latitude, longitude: $0.longitude)
                    < locationService.distanceKm(latitude: $1.latitude, longitude: $1.longitude)
            }
        case .topRated:
            return base.sorted { $0.rating > $1.rating }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(
                leadingIcon: "chevron.left",
                onLeading: { dismiss() },
                title: "Search Results (\(results.count))",
                subtitle: "Modify Search",
                subtitleIsLink: true,
                onSubtitle: { dismiss() },
                trailingIcon: "arrow.up.arrow.down",
                onTrailing: { showSortSheet = true }
            )

            ScrollView {
                VStack(spacing: 14) {
                    if sortOption != .recommended {
                        HStack(spacing: 6) {
                            Image(systemName: sortOption.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text("Sorted by \(sortOption.rawValue.lowercased())")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color.brandOrange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    ForEach(results) { spot in
                        Button {
                            path.append(.spotDetails(spot.id, query))
                        } label: {
                            SearchResultCard(spot: spot, query: query)
                        }
                        .buttonStyle(.plain)
                    }

                    if results.isEmpty {
                        emptyState
                    }

                    if !unavailable.isEmpty {
                        unavailableSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .refreshable {
                await store.refreshSearchResults()
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: sortOption)
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            locationService.requestLocation()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showsUnavailable)
        .sheet(isPresented: $showSortSheet) {
            SortSheet(selection: $sortOption)
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
        }
    }
}

extension SearchResultsView {
    /// Shown when every nearby spot is closed for the chosen window.
    fileprivate var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(Color.placeholderGray)
            Text("No spots open for these times")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.inkPrimary)
            Text("Owners set their own hours. Try another time window or a different day.")
                .font(.system(size: 14))
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
            TextLinkButton(title: "Modify Search") { dismiss() }
        }
        .padding(.top, 50)
        .padding(.horizontal, 20)
    }

    /// Collapsible list of spots excluded by the owner's availability rules.
    fileprivate var unavailableSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    showsUnavailable.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("\(unavailable.count) spot\(unavailable.count == 1 ? "" : "s") closed for your times")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.inkPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.inkSecondary)
                        .rotationEffect(.degrees(showsUnavailable ? 180 : 0))
                }
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(Color.fieldGray)
                .clipShape(.rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            if showsUnavailable {
                ForEach(unavailable) { spot in
                    Button {
                        path.append(.spotDetails(spot.id, query))
                    } label: {
                        SearchResultCard(spot: spot, query: query)
                    }
                    .buttonStyle(.plain)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .padding(.top, results.isEmpty ? 0 : 8)
    }
}

/// Half sheet listing the sort options with a checkmark on the active one.
struct SortSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selection: SpotSortOption

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sort by")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(Color.inkPrimary)
                .padding(.horizontal, 20)
                .padding(.top, 22)

            VStack(spacing: 0) {
                ForEach(SpotSortOption.allCases) { option in
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        selection = option
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: option.icon)
                                .font(.system(size: 17))
                                .foregroundStyle(selection == option ? Color.brandOrange : Color.inkSecondary)
                                .frame(width: 26)
                            Text(option.rawValue)
                                .font(.system(size: 16, weight: selection == option ? .semibold : .regular))
                                .foregroundStyle(Color.inkPrimary)
                            Spacer()
                            if selection == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(Color.brandOrange)
                            }
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 56)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)

                    if option != SpotSortOption.allCases.last {
                        Divider()
                            .overlay(Color.borderGray.opacity(0.5))
                            .padding(.leading, 60)
                    }
                }
            }
            .padding(.top, 6)

            Spacer(minLength: 0)
        }
    }
}

/// Search result card: photo with badges, title, schedule rows, price + rating.
struct SearchResultCard: View {
    @Environment(LocationService.self) private var locationService

    let spot: ParkingSpot
    let query: SearchQuery

    private var check: AvailabilitySchedule.Check { spot.availability(for: query) }
    private var availabilityReason: String? { check.isAvailable ? nil : check.title }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SpotPhoto(name: spot.photos.first ?? "")
                .frame(height: 170)
                .frame(maxWidth: .infinity)
                .clipShape(.rect(cornerRadius: 14))
                .overlay(alignment: .topLeading) {
                    DistanceBadge(
                        text: locationService.distanceLabel(latitude: spot.latitude, longitude: spot.longitude)
                    )
                    .padding(10)
                }
                .overlay(alignment: .topTrailing) {
                    if spot.hasChargingStation {
                        EVBadge()
                            .padding(10)
                    }
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(spot.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.inkPrimary)

                IconMetaRow(icon: "calendar", text: query.dateLabel, secondText: query.duration == .daily ? query.endDateLabel : nil)

                if query.duration == .hourly {
                    IconMetaRow(icon: "clock", text: query.fromTimeLabel, secondText: query.toTimeLabel)
                }

                if let reason = availabilityReason {
                    AvailabilityPill(text: reason)
                } else {
                    IconMetaRow(icon: "checkmark.circle", text: "Open \(spot.schedule.compactSummary)", textColor: .inkSecondary)
                }

                HStack(alignment: .firstTextBaseline) {
                    PriceText(amount: query.totalPrice(for: spot), trailingNote: query.durationNote, size: 22)
                    Spacer()
                    RatingLabel(rating: spot.rating, count: spot.reviewCount)
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(12)
        .background(Color.cardGray)
        .clipShape(.rect(cornerRadius: 18))
        .opacity(check.isAvailable ? 1 : 0.72)
    }
}
