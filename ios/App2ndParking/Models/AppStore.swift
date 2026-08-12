import SwiftUI
import Observation

/// In-memory session store for the prototype. No persistence by design.
@Observable
final class AppStore {
    var activeRole: AppRole?

    var spots: [ParkingSpot] = MockData.spots
    var reservations: [Reservation] = MockData.seedReservations()
    var vehicles: [Vehicle] = MockData.vehicles

    var renterNotifications: [AppNotification] = MockData.renterNotifications
    var listerNotifications: [AppNotification] = MockData.listerNotifications
    var securityNotifications: [AppNotification] = MockData.securityNotifications

    var payouts: [Payout] = MockData.payouts
    var paymentCards: [PaymentCard] = MockData.paymentCards
    var ibanConnected: Bool = false
    var ibanValue: String = ""

    // MARK: - Editable profile

    var profileBio: String = "Based in West Bay — always on the move around Doha."
    var profilePhone: String = "+974 5583 3202"
    var avatarStyle: AvatarStyle = .orange
    /// Custom username per role; falls back to the seeded persona name when unset.
    var profileNames: [AppRole: String] = [:]
    /// Custom profile photo per role (JPEG/PNG data from the photo picker).
    var avatarImages: [AppRole: Data] = [:]

    func defaultName(for role: AppRole) -> String {
        switch role {
        case .renter: return "Nacer Lalaoui"
        case .lister: return "Ahmed Fadi"
        case .security: return "Officer Salim Khan"
        }
    }

    /// Display name used across profile, bookings and passes — custom name wins over the persona default.
    func displayName(for role: AppRole) -> String {
        let custom = profileNames[role]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return custom.isEmpty ? defaultName(for: role) : custom
    }

    /// Applies the username + avatar chosen during signup to the personal roles.
    /// Security keeps its officer persona since it represents building staff.
    func applySignupProfile(name: String, style: AvatarStyle) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        profileNames[.renter] = trimmed
        profileNames[.lister] = trimmed
        avatarStyle = style
    }

    // MARK: - Payment cards

    var defaultPaymentCard: PaymentCard? {
        paymentCards.first { $0.isDefault } ?? paymentCards.first
    }

    func paymentCard(id: UUID) -> PaymentCard? {
        paymentCards.first { $0.id == id }
    }

    func addPaymentCard(_ card: PaymentCard) {
        var newCard = card
        if paymentCards.isEmpty { newCard.isDefault = true }
        if newCard.isDefault { clearDefaultCard() }
        paymentCards.insert(newCard, at: 0)
    }

    func updatePaymentCard(_ card: PaymentCard) {
        guard let index = paymentCards.firstIndex(where: { $0.id == card.id }) else { return }
        if card.isDefault { clearDefaultCard() }
        paymentCards[index] = card
        ensureDefaultCard()
    }

    func deletePaymentCard(id: UUID) {
        paymentCards.removeAll { $0.id == id }
        ensureDefaultCard()
    }

    func setDefaultPaymentCard(id: UUID) {
        for index in paymentCards.indices {
            paymentCards[index].isDefault = paymentCards[index].id == id
        }
    }

    private func clearDefaultCard() {
        for index in paymentCards.indices { paymentCards[index].isDefault = false }
    }

    /// Keeps exactly one default card whenever cards exist.
    private func ensureDefaultCard() {
        guard !paymentCards.isEmpty, !paymentCards.contains(where: \.isDefault) else { return }
        paymentCards[0].isDefault = true
    }

    // MARK: - Recent searches

    private static let recentSearchesKey = "recentSearchLocations"

    /// Last three searched locations, persisted locally so they survive relaunch.
    private(set) var recentSearchLocations: [String] = UserDefaults.standard.stringArray(forKey: AppStore.recentSearchesKey) ?? []

    /// Records a searched location, deduplicated and capped at three entries.
    func addRecentSearchLocation(_ location: String) {
        let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var updated = recentSearchLocations.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        updated.insert(trimmed, at: 0)
        recentSearchLocations = Array(updated.prefix(3))
        UserDefaults.standard.set(recentSearchLocations, forKey: AppStore.recentSearchesKey)
    }

    /// Renter verification gate — flips true after the wizard succeeds once.
    var isRenterVerified: Bool = false
    /// Debug switch reachable from Profile: forces verification/payment failure states.
    var simulateFailures: Bool = false

    // MARK: - Derived collections

    var activeRenterReservation: Reservation? {
        reservations.first { $0.status == .active }
    }

    /// Count shown as the booking alert badge on the renter Reservations tab.
    var renterBookingAlertCount: Int {
        reservations.filter { $0.status == .active || $0.status == .upcoming }.count
    }

    func reservations(with status: ReservationStatus) -> [Reservation] {
        reservations.filter { $0.status == status }
    }

    func reservation(id: UUID) -> Reservation? {
        reservations.first { $0.id == id }
    }

    func spot(id: UUID) -> ParkingSpot? {
        spots.first { $0.id == id }
    }

    /// Spots in the searched area, regardless of the lister's availability rules.
    func searchCandidates(for query: SearchQuery) -> [ParkingSpot] {
        let available = spots.filter { $0.status != .archived }
        let matching = available.filter { $0.price(for: query.duration) != nil }
        let base = matching.isEmpty ? available : matching

        // Loose location match on the first token of the picked suggestion ("West Bay, Doha" → "West Bay").
        let token = query.location.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !token.isEmpty, token.lowercased() != "near me" else { return base }
        let localized = base.filter { $0.address.localizedCaseInsensitiveContains(token) }
        return localized.isEmpty ? base : localized
    }

    /// Spots that are open for the requested dates and times, best matches first.
    func searchResults(for query: SearchQuery) -> [ParkingSpot] {
        searchCandidates(for: query).filter { $0.availability(for: query).isAvailable }
    }

    /// Spots in the area whose availability rules exclude the requested window.
    func unavailableResults(for query: SearchQuery) -> [ParkingSpot] {
        searchCandidates(for: query).filter { !$0.availability(for: query).isAvailable }
    }

    func unreadCount(for role: AppRole) -> Int {
        notifications(for: role).filter(\.isUnread).count
    }

    func notifications(for role: AppRole) -> [AppNotification] {
        switch role {
        case .renter: return renterNotifications
        case .lister: return listerNotifications
        case .security: return securityNotifications
        }
    }

    func markNotificationsRead(for role: AppRole) {
        switch role {
        case .renter: renterNotifications = renterNotifications.map { note in withRead(note) }
        case .lister: listerNotifications = listerNotifications.map { note in withRead(note) }
        case .security: securityNotifications = securityNotifications.map { note in withRead(note) }
        }
    }

    private func withRead(_ note: AppNotification) -> AppNotification {
        var copy = note
        copy.isUnread = false
        return copy
    }

    // MARK: - Simulated server refresh

    private var refreshedNotificationRoles: Set<AppRole> = []

    /// Simulates fetching notifications from the server. The first pull per role delivers one fresh item.
    func refreshNotifications(for role: AppRole) async {
        try? await Task.sleep(for: .seconds(1.1))
        guard !refreshedNotificationRoles.contains(role) else { return }
        refreshedNotificationRoles.insert(role)

        let fresh: AppNotification
        switch role {
        case .renter:
            fresh = AppNotification(id: UUID(), title: "New spots near you", message: "3 new parking spots were just listed around West Bay.", timeAgo: "now", isUnread: true, tint: .orange, icon: "sparkles")
        case .lister:
            fresh = AppNotification(id: UUID(), title: "Your listing is trending", message: "P2-032 was viewed 12 times in the last hour.", timeAgo: "now", isUnread: true, tint: .blue, icon: "chart.line.uptrend.xyaxis")
        case .security:
            fresh = AppNotification(id: UUID(), title: "Roster updated", message: "Tomorrow's shift roster for LIV Residence has been published.", timeAgo: "now", isUnread: true, tint: .blue, icon: "calendar.badge.clock")
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            switch role {
            case .renter: renterNotifications.insert(fresh, at: 0)
            case .lister: listerNotifications.insert(fresh, at: 0)
            case .security: securityNotifications.insert(fresh, at: 0)
            }
        }
    }

    /// Simulates re-fetching search results from the server.
    func refreshSearchResults() async {
        try? await Task.sleep(for: .seconds(1))
    }

    // MARK: - Mutations

    @discardableResult
    func createReservation(spot: ParkingSpot, query: SearchQuery, vehicle: Vehicle?, guestName: String, guestPhone: String, plate: String, paymentMethod: PaymentRecord.Method? = nil) -> Reservation {
        let reservationID = UUID()
        let payment = paymentMethod.map { method in
            PaymentRecord(
                method: method,
                amount: query.totalPrice(for: spot),
                paidAtLabel: Date.now.formatted(date: .abbreviated, time: .shortened),
                reference: "2P-\(String(reservationID.uuidString.prefix(8)).uppercased())"
            )
        }
        let reservation = Reservation(
            id: reservationID,
            spot: spot,
            duration: query.duration,
            dateLabel: query.dateLabel,
            endDateLabel: query.duration == .daily ? query.endDateLabel : nil,
            startTime: query.duration == .hourly ? query.fromTimeLabel : nil,
            endTime: query.duration == .hourly ? query.toTimeLabel : nil,
            totalPrice: query.totalPrice(for: spot),
            status: .upcoming,
            stage: .completed,
            vehicleBrand: vehicle?.brand ?? "—",
            vehicleModel: vehicle?.model ?? "Custom",
            plateNumber: vehicle?.plate ?? plate,
            guestName: guestName.isEmpty ? displayName(for: .renter) : guestName,
            guestPhone: guestPhone.isEmpty ? profilePhone : guestPhone,
            residentName: spot.listerName,
            unitNumber: "402",
            countdown: nil,
            payment: payment
        )
        reservations.insert(reservation, at: 0)
        return reservation
    }

    func updateReservationStatus(id: UUID, to status: ReservationStatus) {
        guard let index = reservations.firstIndex(where: { $0.id == id }) else { return }
        reservations[index].status = status
        reservations[index].countdown = status == .active ? "3:59" : nil
    }

    func advanceStage(id: UUID, to stage: RequestStage) {
        guard let index = reservations.firstIndex(where: { $0.id == id }) else { return }
        reservations[index].stage = stage
        if stage == .completed {
            reservations[index].status = .upcoming
            reservations[index].isContractSigned = true
        }
    }

    func cancelReservation(id: UUID) {
        updateReservationStatus(id: id, to: .cancelled)
    }

    /// Clock label for "now", used when stamping check-in / check-out times.
    private static let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    var nowClockLabel: String { AppStore.clockFormatter.string(from: .now) }

    /// Verifies a guest at the gate: stamps the arrival time and starts the stay.
    func checkIn(reservationID: UUID) {
        guard let index = reservations.firstIndex(where: { $0.id == reservationID }) else { return }
        reservations[index].status = .active
        reservations[index].countdown = reservations[index].countdown ?? "3:59"
        reservations[index].checkedInAtLabel = nowClockLabel
        reservations[index].checkedOutAtLabel = nil
        reservations[index].lateArrivalMinutes = 0
    }

    /// Releases a vehicle at the gate: stamps the exit time and closes the stay.
    func checkOut(reservationID: UUID) {
        guard let index = reservations.firstIndex(where: { $0.id == reservationID }) else { return }
        reservations[index].checkedOutAtLabel = nowClockLabel
        reservations[index].status = .past
        reservations[index].countdown = nil
        reservations[index].lateArrivalMinutes = 0
    }

    /// Reservations still inside the garage, overstays first.
    var vehiclesInside: [Reservation] {
        reservations.filter { $0.securityState.isInside }
            .sorted { ($0.securityState == .overstay ? 0 : 1) < ($1.securityState == .overstay ? 0 : 1) }
    }

    /// Stays that need officer attention (late arrivals + overstays).
    var checkInAlerts: [Reservation] {
        reservations.filter { $0.securityState.needsAttention }
    }

    // MARK: - Listing availability

    /// Saves the lister's weekly availability rules for a spot.
    func updateSchedule(spotID: UUID, schedule: AvailabilitySchedule) {
        guard let index = spots.firstIndex(where: { $0.id == spotID }) else { return }
        spots[index].schedule = schedule
    }

    /// Blocks or unblocks a single date on a listing ("I need the spot that day").
    func toggleBlockedDate(spotID: UUID, date: Date) {
        guard let index = spots.firstIndex(where: { $0.id == spotID }) else { return }
        spots[index].schedule.toggleBlocked(date)
    }

    /// Upcoming reservations that would clash with a schedule the lister is about to save.
    func conflicts(for spotID: UUID, schedule: AvailabilitySchedule) -> [Reservation] {
        reservations.filter { reservation in
            guard reservation.spot.id == spotID,
                  reservation.status == .upcoming || reservation.status == .active,
                  let day = reservation.bookedWeekday else { return false }
            if reservation.duration == .hourly {
                guard schedule.allowsHourly else { return true }
                let window = schedule.window(for: day)
                guard window.isOpen else { return true }
                guard let from = reservation.startMinutes, let to = reservation.endMinutes else { return false }
                return !window.covers(fromMinutes: from, toMinutes: to)
            }
            guard schedule.allowsDaily else { return true }
            return !schedule.dailyDays.contains(day)
        }
    }

    func addVehicle(_ vehicle: Vehicle) {
        vehicles.append(vehicle)
    }

    @discardableResult
    func addListing(building: String, level: String, spotNumber: String, accessType: String, vehicleSize: String, hasCharging: Bool, securityType: String, description: String, hourly: Double?, daily: Double?, schedule: AvailabilitySchedule = .alwaysOpen) -> ParkingSpot {
        let spot = ParkingSpot(
            id: UUID(),
            spotCode: spotNumber.isEmpty ? "P1-001" : spotNumber,
            buildingName: building.isEmpty ? "LIV Residence" : building,
            address: "\(building.isEmpty ? "LIV Residence" : building), West Bay, Doha, Qatar",
            level: level.isEmpty ? "Basement 1" : level,
            accessType: accessType,
            maxVehicleHeight: vehicleSize,
            schedule: schedule,
            hasChargingStation: hasCharging,
            securityType: securityType,
            description: description.isEmpty ? "Covered spot with easy access, close to the elevators." : description,
            photos: ["ev_charging_garage", "underground_parking_garage", "parking_deck_residential"],
            pricePerHour: hourly,
            pricePerDay: daily,
            rating: 0,
            reviewCount: 0,
            listerName: "Ahmed Fadi",
            listerVerified: true,
            status: .live,
            accessInstructions: MockData.defaultInstructions,
            cancellationPolicy: MockData.defaultPolicy
        )
        spots.insert(spot, at: 0)
        return spot
    }
}
