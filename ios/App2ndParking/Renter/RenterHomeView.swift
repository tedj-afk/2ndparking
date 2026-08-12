import SwiftUI
import MapKit

/// Renter home: Airbnb-style full-bleed map with price-pill markers,
/// a floating search container at the bottom, and a spot preview card on marker tap.
struct RenterHomeView: View {
    @Environment(AppStore.self) private var store
    @Environment(LocationService.self) private var locationService

    @Binding var path: [RenterRoute]

    @State private var query = SearchQuery()
    @State private var cameraPosition: MapCameraPosition = .region(RenterHomeView.dohaRegion)
    @State private var selectedSpotID: UUID?
    @State private var showSearchSheet: Bool = false
    @State private var activeFilter: SpotMapFilter = .all
    @State private var cameraCenter: CLLocationCoordinate2D = RenterHomeView.dohaRegion.center
    @State private var searchAnchor: CLLocationCoordinate2D = RenterHomeView.dohaRegion.center
    @State private var showsSearchAreaButton: Bool = false
    @State private var isSearchingArea: Bool = false

    /// Pan distance from the last searched area before the "Search this area" button appears.
    private static let searchAreaThresholdMeters: Double = 1_500

    /// Region covering the seeded Doha spots.
    static let dohaRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 25.2660, longitude: 51.5310),
        span: MKCoordinateSpan(latitudeDelta: 0.17, longitudeDelta: 0.17)
    )

    private var canSearch: Bool {
        !query.location.isEmpty && (query.duration == .daily || query.toTime > query.fromTime)
    }

    private var visibleSpots: [ParkingSpot] {
        store.spots.filter { $0.status != .archived && activeFilter.matches($0) }
    }

    private var selectedSpot: ParkingSpot? {
        guard let selectedSpotID else { return nil }
        return store.spot(id: selectedSpotID)
    }

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 12) {
                header
                if showsSearchAreaButton {
                    searchAreaButton
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showsSearchAreaButton)
        }
        .safeAreaInset(edge: .bottom) {
            bottomPanel
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            locationService.requestLocation()
        }
        .sheet(isPresented: $showSearchSheet) {
            searchSheet
        }
    }

    // MARK: - Map

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            ForEach(visibleSpots) { spot in
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude), anchor: .bottom) {
                    SpotPricePill(spot: spot, isSelected: selectedSpotID == spot.id) {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedSpotID = selectedSpotID == spot.id ? nil : spot.id
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControlVisibility(.hidden)
        .onMapCameraChange(frequency: .onEnd) { context in
            cameraCenter = context.region.center
            let pannedDistance = CLLocation(latitude: cameraCenter.latitude, longitude: cameraCenter.longitude)
                .distance(from: CLLocation(latitude: searchAnchor.latitude, longitude: searchAnchor.longitude))
            showsSearchAreaButton = pannedDistance > Self.searchAreaThresholdMeters
        }
    }

    // MARK: - Overlays

    private var header: some View {
        HStack(alignment: .top) {
            BrandLogo()
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .liquidGlass(in: Capsule())

            Spacer()

            GlassCircleButton(systemName: "location") {
                locationService.requestLocation()
                withAnimation(.easeInOut(duration: 0.6)) {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: locationService.currentLocation.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    )
                }
            }
        }
    }

    /// Floating pill that re-runs the search around the panned map region.
    private var searchAreaButton: some View {
        Button {
            searchThisArea()
        } label: {
            HStack(spacing: 7) {
                if isSearchingArea {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Color.brandOrange)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.brandOrange)
                }
                Text(isSearchingArea ? "Searching…" : "Search this area")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.inkPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(.capsule)
            .overlay(
                Capsule()
                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isSearchingArea)
    }

    /// Re-anchors the search to the panned map center and refreshes results.
    private func searchThisArea() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        isSearchingArea = true
        Task {
            await store.refreshSearchResults()
            searchAnchor = cameraCenter
            // Reflect the panned area in the search summary using the nearest known area.
            let nearest = LocationSuggestion.dohaSuggestions.min { first, second in
                distanceFromCenter(latitude: first.latitude, longitude: first.longitude)
                    < distanceFromCenter(latitude: second.latitude, longitude: second.longitude)
            }
            if let nearest {
                query.location = "\(nearest.name), Doha"
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isSearchingArea = false
                showsSearchAreaButton = false
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func distanceFromCenter(latitude: Double, longitude: Double) -> Double {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: cameraCenter.latitude, longitude: cameraCenter.longitude))
    }

    private var bottomPanel: some View {
        VStack(spacing: 12) {
            if let spot = selectedSpot {
                MapSpotPreviewCard(
                    spot: spot,
                    onClose: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedSpotID = nil
                        }
                    },
                    onOpen: {
                        path.append(.spotDetails(spot.id, defaultQuery(for: spot)))
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            filterChips

            searchContainer
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedSpotID)
    }

    /// Quick map filters shown directly above the search bar.
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SpotMapFilter.allCases) { filter in
                    MapFilterChip(filter: filter, isSelected: activeFilter == filter) {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            activeFilter = filter
                            if let selectedSpotID, let spot = store.spot(id: selectedSpotID), !filter.matches(spot) {
                                self.selectedSpotID = nil
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
        .scrollClipDisabled()
    }

    /// Collapsed Airbnb-style search pill that opens the full search sheet.
    private var searchContainer: some View {
        Button {
            showSearchSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.brandOrange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(query.location.isEmpty ? "Where to park?" : query.location)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.inkPrimary)
                        .lineLimit(1)
                    Text("\(query.duration == .hourly ? "Hourly" : "Daily") · \(query.dateLabel)")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.inkPrimary)
                    .frame(width: 38, height: 38)
                    .background(Color.cardGray)
                    .clipShape(.circle)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(Color.white)
            .clipShape(.capsule)
            .overlay(
                Capsule()
                    .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.16), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var searchSheet: some View {
        ScrollView {
            FindParkingCard(query: $query, canSearch: canSearch) {
                store.addRecentSearchLocation(query.location)
                showSearchSheet = false
                Task {
                    try? await Task.sleep(for: .milliseconds(420))
                    path.append(.searchResults(query))
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.scrolls)
    }

    private func defaultQuery(for spot: ParkingSpot) -> SearchQuery {
        var spotQuery = SearchQuery()
        spotQuery.duration = spot.primaryDuration
        spotQuery.location = "\(spot.areaName), Doha"
        return spotQuery
    }
}

/// Quick filters for the map's spot markers.
enum SpotMapFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case ev = "EV Charging"
    case covered = "Covered"
    case monthly = "Monthly"

    var id: String { rawValue }

    var icon: String? {
        switch self {
        case .all: return nil
        case .ev: return "bolt.fill"
        case .covered: return "door.garage.closed"
        case .monthly: return "calendar"
        }
    }

    func matches(_ spot: ParkingSpot) -> Bool {
        switch self {
        case .all: return true
        case .ev: return spot.hasChargingStation
        case .covered: return spot.isCovered
        case .monthly: return spot.supportsMonthly
        }
    }
}

/// Capsule chip used in the map filter row.
private struct MapFilterChip: View {
    let filter: SpotMapFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon = filter.icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(filter.rawValue)
                    .font(.system(size: 13.5, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : Color.inkPrimary)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(isSelected ? Color.brandOrange : Color.white)
            .clipShape(.capsule)
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

/// Airbnb-style price pill marker on the map. Selected pill flips to brand orange.
private struct SpotPricePill: View {
    let spot: ParkingSpot
    let isSelected: Bool
    let action: () -> Void

    private var priceLabel: String {
        if let hourly = spot.pricePerHour { return "\(Int(hourly)) QAR" }
        if let daily = spot.pricePerDay { return "\(Int(daily)) QAR" }
        return spot.spotCode
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if spot.hasChargingStation {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isSelected ? .white : Color.successGreen)
                }
                Text(priceLabel)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isSelected ? .white : Color.inkPrimary)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(isSelected ? Color.brandOrange : Color.white)
            .clipShape(.capsule)
            .overlay(
                Capsule()
                    .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            .scaleEffect(isSelected ? 1.12 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

/// Compact preview card shown above the search container when a map pin is selected.
private struct MapSpotPreviewCard: View {
    @Environment(LocationService.self) private var locationService

    let spot: ParkingSpot
    let onClose: () -> Void
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                SpotPhoto(name: spot.photos.first ?? "")
                    .frame(width: 92, height: 92)
                    .clipShape(.rect(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(spot.buildingName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.inkPrimary)
                            .lineLimit(1)
                        Spacer(minLength: 24)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.inkPrimary)
                        Text(String(format: "%.1f", spot.rating))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.inkPrimary)
                        Text("· \(locationService.distanceLabel(latitude: spot.latitude, longitude: spot.longitude)) away")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.inkSecondary)
                    }
                    Text("\(spot.areaName), Doha")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkSecondary)
                        .lineLimit(1)
                    if let hourly = spot.pricePerHour {
                        Text("\(Int(hourly)) QAR / hour")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.inkPrimary)
                    } else if let daily = spot.pricePerDay {
                        Text("\(Int(daily)) QAR / day")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.inkPrimary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(10)
            .background(Color.white)
            .clipShape(.rect(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.16), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.inkSecondary)
                    .frame(width: 26, height: 26)
                    .background(Color.cardGray)
                    .clipShape(.circle)
            }
            .padding(10)
        }
    }
}

/// The duration-aware search form with location autocomplete and native pickers.
struct FindParkingCard: View {
    @Environment(AppStore.self) private var store
    @Environment(LocationService.self) private var locationService

    @Binding var query: SearchQuery
    let canSearch: Bool
    let onSearch: () -> Void

    @FocusState private var locationFocused: Bool

    private var suggestions: [LocationSuggestion] {
        guard locationFocused else { return [] }
        let matches = LocationSuggestion.matching(query.location)
        if matches.count == 1, "\(matches[0].name), Doha" == query.location { return [] }
        return Array(matches.prefix(5))
    }

    /// Recent searches surface as soon as the field is focused and still empty.
    private var recentSearches: [String] {
        guard locationFocused, query.location.isEmpty else { return [] }
        return store.recentSearchLocations
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Find a parking spot")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.inkPrimary)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 8) {
                Text("Duration")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.inkPrimary)
                SegmentedPillSelector(selection: $query.duration)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            locationField

            switch query.duration {
            case .hourly:
                DatePickerField(label: "Date", date: $query.startDate)
                HStack(spacing: 12) {
                    TimePickerField(label: "From", time: $query.fromTime)
                    TimePickerField(label: "To", time: $query.toTime)
                }
            case .daily:
                DatePickerField(label: "Start", date: $query.startDate)
                DatePickerField(label: "End", date: $query.endDate, range: query.startDate...)
            }

            PrimaryButton(title: "Search", isEnabled: canSearch) {
                locationFocused = false
                onSearch()
            }
            .padding(.top, 6)
        }
        .padding(16)
        .background(Color.cardGray)
        .clipShape(.rect(cornerRadius: 20))
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: query.duration)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: suggestions)
    }

    private var locationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.inkPrimary)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.inkSecondary)
                TextField("Search area or building", text: $query.location)
                    .font(.system(size: 15))
                    .focused($locationFocused)
                    .autocorrectionDisabled()
                if !query.location.isEmpty {
                    Button {
                        query.location = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.placeholderGray)
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 54)
            .background(Color.white)
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(locationFocused ? Color.brandOrange : Color.borderGray, lineWidth: locationFocused ? 1.5 : 1)
            )

            if locationFocused {
                VStack(spacing: 0) {
                    suggestionRow(
                        icon: "location.fill",
                        iconTint: .brandOrange,
                        title: "Use my location",
                        detail: "Find spots near you"
                    ) {
                        useMyLocation()
                    }

                    ForEach(recentSearches, id: \.self) { recent in
                        Divider().overlay(Color.borderGray.opacity(0.5)).padding(.leading, 46)
                        suggestionRow(
                            icon: "clock.arrow.circlepath",
                            iconTint: .inkSecondary,
                            title: recent,
                            detail: "Recent search"
                        ) {
                            query.location = recent
                            locationFocused = false
                        }
                    }

                    ForEach(suggestions) { suggestion in
                        Divider().overlay(Color.borderGray.opacity(0.5)).padding(.leading, 46)
                        suggestionRow(
                            icon: "mappin.circle.fill",
                            iconTint: .inkSecondary,
                            title: suggestion.name,
                            detail: suggestion.detail
                        ) {
                            query.location = "\(suggestion.name), Doha"
                            locationFocused = false
                        }
                    }
                }
                .background(Color.white)
                .clipShape(.rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderGray, lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: locationFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: recentSearches)
    }

    private func suggestionRow(icon: String, iconTint: Color, title: String, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconTint)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.inkPrimary)
                    Text(detail)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.inkSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 52)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func useMyLocation() {
        locationService.requestLocation()
        let nearest = LocationSuggestion.dohaSuggestions.min { first, second in
            locationService.distanceKm(latitude: first.latitude, longitude: first.longitude)
                < locationService.distanceKm(latitude: second.latitude, longitude: second.longitude)
        }
        query.location = "\(nearest?.name ?? "West Bay"), Doha"
        locationFocused = false
    }
}
