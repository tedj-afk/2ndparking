import SwiftUI

enum AppRole: String, CaseIterable, Identifiable {
    case renter = "Renter"
    case lister = "Lister"
    case security = "Security"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .renter: return "Find and book parking spots in residential towers"
        case .lister: return "Rent out your unused parking spot"
        case .security: return "Check guests in and out via QR code"
        }
    }

    var symbol: String {
        switch self {
        case .renter: return "car.fill"
        case .lister: return "key.fill"
        case .security: return "shield.checkered"
        }
    }
}

enum ParkingDuration: String, CaseIterable, Identifiable {
    case hourly = "Hourly"
    case daily = "Daily"

    var id: String { rawValue }
}

enum ReservationStatus: String, CaseIterable {
    case active = "Active"
    case upcoming = "Upcoming"
    case pending = "Pending"
    case past = "Past"
    case cancelled = "Cancelled"

    var dotColor: Color {
        switch self {
        case .active: return .successGreen
        case .upcoming: return .infoBlue
        case .pending: return .pendingAmber
        case .past: return Color.inkTertiary
        case .cancelled: return .failureRed
        }
    }
}

/// Security-facing lifecycle of a guest's physical stay in the garage.
enum SecurityCheckState: String, CaseIterable {
    case awaitingArrival = "Awaiting arrival"
    case lateArrival = "Late arrival"
    case parked = "Parked"
    case overstay = "Overstay"
    case checkedOut = "Checked out"
    case checkedOutLate = "Checked out late"

    var tint: Color {
        switch self {
        case .awaitingArrival: return .infoBlue
        case .lateArrival: return .pendingAmber
        case .parked: return .successGreen
        case .overstay: return .failureRed
        case .checkedOut: return Color.inkTertiary
        case .checkedOutLate: return .pendingAmber
        }
    }

    var icon: String {
        switch self {
        case .awaitingArrival: return "clock"
        case .lateArrival: return "clock.badge.exclamationmark"
        case .parked: return "car.fill"
        case .overstay: return "exclamationmark.triangle.fill"
        case .checkedOut: return "flag.checkered"
        case .checkedOutLate: return "flag.checkered"
        }
    }

    /// True while the vehicle is still inside the garage.
    var isInside: Bool { self == .parked || self == .overstay }

    /// True once the vehicle has left.
    var isClosed: Bool { self == .checkedOut || self == .checkedOutLate }

    /// True when the stay needs officer attention (late arrival or overstay).
    var needsAttention: Bool { self == .lateArrival || self == .overstay }
}

enum ListingStatus: String, CaseIterable {
    case live = "Live"
    case free = "Free"
    case reserved = "Reserved"
    case archived = "Archived"

    var dotColor: Color {
        switch self {
        case .live, .free: return .successGreen
        case .reserved: return .brandOrange
        case .archived: return Color.inkTertiary
        }
    }

    var pillBackground: Color {
        switch self {
        case .live, .free: return .successPale
        case .reserved: return .orangePale
        case .archived: return .fieldGray
        }
    }
}

enum RequestStage: Int, CaseIterable, Comparable {
    case requested = 0
    case accepted = 1
    case payDeposit = 2
    case sign = 3
    case completed = 4

    static func < (lhs: RequestStage, rhs: RequestStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .requested: return "Requested"
        case .accepted: return "Accepted"
        case .payDeposit: return "Pay deposit"
        case .sign: return "Sign"
        case .completed: return "Done"
        }
    }
}

struct ParkingSpot: Identifiable, Hashable {
    let id: UUID
    var spotCode: String
    var buildingName: String
    var address: String
    var level: String
    var accessType: String
    var maxVehicleHeight: String
    /// Weekly availability rules set by the lister (hours, open days, night limits, blocked dates).
    var schedule: AvailabilitySchedule = .alwaysOpen
    var hasChargingStation: Bool
    var securityType: String
    var description: String
    var photos: [String]
    var pricePerHour: Double?
    var pricePerDay: Double?
    var rating: Double
    var reviewCount: Int
    var listerName: String
    var listerVerified: Bool
    var status: ListingStatus
    var accessInstructions: [String]
    var cancellationPolicy: String
    var latitude: Double = 25.3208
    var longitude: Double = 51.5305
    /// Whether the lister accepts monthly arrangements for this spot.
    var supportsMonthly: Bool = false

    var title: String { "\(spotCode) | \(buildingName)" }

    /// One-line availability label, derived from the lister's weekly schedule.
    var availableTimes: String { schedule.compactSummary }

    /// True when renters can currently request this spot at all.
    var isBookable: Bool {
        status != .archived && !schedule.isPaused && !schedule.hasNoOpenDays && !schedule.offeredDurations.isEmpty
    }

    /// Covered spots sit on basement or podium levels.
    var isCovered: Bool {
        level.localizedCaseInsensitiveContains("Basement") || level.localizedCaseInsensitiveContains("Podium")
    }

    var primaryDuration: ParkingDuration {
        if pricePerHour != nil { return .hourly }
        return .daily
    }

    /// Availability + pricing test for a search request.
    func availability(for query: SearchQuery) -> AvailabilitySchedule.Check {
        guard price(for: query.duration) != nil else {
            return .blocked(
                "\(query.duration.rawValue) unavailable",
                "This spot isn't priced for \(query.duration.rawValue.lowercased()) stays yet."
            )
        }
        return schedule.check(query)
    }

    /// Area portion of the address (e.g. "West Bay").
    var areaName: String {
        let parts = address.components(separatedBy: ", ")
        guard parts.count >= 3 else { return "Doha" }
        return parts[parts.count - 3]
    }

    func price(for duration: ParkingDuration) -> Double? {
        switch duration {
        case .hourly: return pricePerHour
        case .daily: return pricePerDay
        }
    }
}

/// Record of a completed payment attached to a reservation.
struct PaymentRecord: Hashable {
    enum Method: Hashable {
        case applePay
        case card(CardBrand, last4: String)
        case qpay
    }

    var method: Method
    var amount: Double
    var paidAtLabel: String
    var reference: String

    var methodTitle: String {
        switch method {
        case .applePay: return "Apple Pay"
        case .card(let brand, let last4): return "\(brand.rawValue) •••• \(last4)"
        case .qpay: return "QPay · Local Debit"
        }
    }
}

struct Reservation: Identifiable, Hashable {
    let id: UUID
    var spot: ParkingSpot
    var duration: ParkingDuration
    var dateLabel: String
    var endDateLabel: String?
    var startTime: String?
    var endTime: String?
    var totalPrice: Double
    var status: ReservationStatus
    var stage: RequestStage
    var vehicleBrand: String
    var vehicleModel: String
    var plateNumber: String
    var guestName: String
    var guestPhone: String
    var residentName: String?
    var unitNumber: String?
    var countdown: String?
    var payment: PaymentRecord? = nil
    var isContractSigned: Bool = false
    /// Clock label of the security check-in, nil until the guest is verified at the gate.
    var checkedInAtLabel: String? = nil
    /// Clock label of the security check-out, nil while the vehicle is still inside.
    var checkedOutAtLabel: String? = nil
    /// Minutes stayed past the booked end time (0 when on time).
    var overstayMinutes: Int = 0
    /// Minutes past the booked start time with no arrival yet (0 when not late).
    var lateArrivalMinutes: Int = 0

    var title: String { spot.title }

    var priceNote: String { "for \(bookedDurationLabel)" }

    // MARK: - Security check-in / check-out

    /// Where this stay currently sits in the gate lifecycle.
    var securityState: SecurityCheckState {
        if checkedOutAtLabel != nil {
            return overstayMinutes > 0 ? .checkedOutLate : .checkedOut
        }
        if checkedInAtLabel != nil || status == .active {
            return overstayMinutes > 0 ? .overstay : .parked
        }
        if lateArrivalMinutes > 0 { return .lateArrival }
        return .awaitingArrival
    }

    /// Officer can scan this guest in.
    var canCheckIn: Bool {
        checkedInAtLabel == nil && checkedOutAtLabel == nil
            && (status == .upcoming || status == .pending || status == .active)
    }

    /// Officer can release this vehicle.
    var canCheckOut: Bool { securityState.isInside }

    /// Time remaining before the booked check-out, e.g. "3:59 left".
    var checkOutCountdownLabel: String? {
        guard securityState == .parked, let countdown else { return nil }
        return countdown
    }

    /// Human delay label for late arrivals and overstays, e.g. "47 min over".
    var delayLabel: String? {
        switch securityState {
        case .lateArrival:
            return "\(Self.minutesLabel(lateArrivalMinutes)) late"
        case .overstay:
            return "\(Self.minutesLabel(overstayMinutes)) over"
        case .checkedOutLate:
            return "\(Self.minutesLabel(overstayMinutes)) over"
        default:
            return nil
        }
    }

    /// Fee charged for an overstay at the spot's hourly rate, rounded up per 15 min block.
    var overstayFee: Double? {
        guard overstayMinutes > 0 else { return nil }
        let hourly = spot.pricePerHour ?? 10
        let blocks = Double((overstayMinutes + 14) / 15)
        return (hourly / 4 * blocks).rounded()
    }

    /// "1 h 12 min" / "47 min" formatting for delay durations.
    static func minutesLabel(_ minutes: Int) -> String {
        guard minutes >= 60 else { return "\(minutes) min" }
        let hours = minutes / 60
        let rest = minutes % 60
        return rest == 0 ? "\(hours) h" : "\(hours) h \(rest) min"
    }

    // MARK: - Availability matching

    /// Weekday the stay starts on, parsed from the stored date label.
    var bookedWeekday: Weekday? {
        Self.parseDay(dateLabel).map { Weekday.from($0) }
    }

    /// Start time as minutes from midnight (hourly bookings only).
    var startMinutes: Int? {
        startTime.flatMap { Self.parseTime($0) }.map { AvailabilitySchedule.minutes(of: $0) }
    }

    /// End time as minutes from midnight (hourly bookings only).
    var endMinutes: Int? {
        endTime.flatMap { Self.parseTime($0) }.map { AvailabilitySchedule.minutes(of: $0) }
    }

    /// Total booked timeframe, e.g. "4 hours" or "3 days".
    var bookedDurationLabel: String {
        switch duration {
        case .hourly:
            if let start = startTime, let end = endTime,
               let from = Self.parseTime(start), let to = Self.parseTime(end) {
                var interval = to.timeIntervalSince(from)
                if interval < 0 { interval += 24 * 3600 } // overnight wrap
                let hours = max(1, Int((interval / 3600).rounded()))
                return "\(hours) hour\(hours == 1 ? "" : "s")"
            }
            return "Hourly"
        case .daily:
            if let endLabel = endDateLabel,
               let from = Self.parseDay(dateLabel), let to = Self.parseDay(endLabel) {
                var days = Calendar.current.dateComponents([.day], from: from, to: to).day ?? 0
                if days < 0 { days += 365 } // year wrap (Dec → Jan)
                let count = max(1, days)
                return "\(count) day\(count == 1 ? "" : "s")"
            }
            return "Daily"
        }
    }

    // MARK: - Label parsing (labels are stored as display strings)

    private static let timeParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let dayParsers: [DateFormatter] = ["MMM d", "EEE, d MMM", "dd/MM/yyyy"].map { format in
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }

    private static func parseTime(_ label: String) -> Date? {
        timeParser.date(from: label)
    }

    private static func parseDay(_ label: String) -> Date? {
        let calendar = Calendar.current
        if label == "Today" { return calendar.startOfDay(for: .now) }
        if label == "Tomorrow" {
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now))
        }
        // Strip ordinal suffixes: "Dec 06th" → "Dec 06", "Dec 1st" → "Dec 1".
        let cleaned = label.replacing(/(\d+)(st|nd|rd|th)/) { match in String(match.1) }
        for parser in dayParsers {
            if let date = parser.date(from: cleaned) { return date }
        }
        return nil
    }
}

struct Vehicle: Identifiable, Hashable {
    let id: UUID
    var brand: String
    var model: String
    var plate: String
}

struct AppNotification: Identifiable, Hashable {
    let id: UUID
    var title: String
    var message: String
    var timeAgo: String
    var isUnread: Bool
    var tint: NotificationTint
    var icon: String = "bell.fill"
    /// When set, tapping the row navigates to this reservation's detail screen.
    var reservationID: UUID? = nil
    var opensRequest: Bool = false

    enum NotificationTint: Hashable {
        case orange, blue, green

        var color: Color {
            switch self {
            case .orange: return .orangePale
            case .blue: return .infoPale
            case .green: return .successPale
            }
        }

        var iconColor: Color {
            switch self {
            case .orange: return .brandOrange
            case .blue: return .infoBlue
            case .green: return .successGreen
            }
        }
    }
}

/// Selectable avatar color style, editable from the profile sheet.
enum AvatarStyle: Int, CaseIterable, Identifiable {
    case orange, blue, green, amber, graphite

    var id: Int { rawValue }

    var foreground: Color {
        switch self {
        case .orange: return .brandOrange
        case .blue: return .infoBlue
        case .green: return .successGreen
        case .amber: return .pendingAmber
        case .graphite: return .inkPrimary
        }
    }

    var background: Color {
        switch self {
        case .orange: return .orangePale
        case .blue: return .infoPale
        case .green: return .successPale
        case .amber: return Color.pendingAmber.opacity(0.18)
        case .graphite: return .fieldGray
        }
    }
}

/// Card networks supported at checkout. Visa/Mastercard are stored credit cards;
/// Himyan and NAPS are Qatari debit schemes charged through the QPay gateway.
enum CardBrand: String, CaseIterable, Identifiable, Hashable {
    case visa = "Visa"
    case mastercard = "Mastercard"
    case himyan = "Himyan"
    case naps = "NAPS"

    var id: String { rawValue }

    /// Local debit schemes settle through QPay instead of being stored on file.
    var isLocalDebit: Bool { self == .himyan || self == .naps }

    /// First-digit detection: 4 → Visa, 2/5 → Mastercard, 6 → Himyan, 9 → NAPS.
    static func detect(fromDigits digits: String) -> CardBrand? {
        switch digits.first {
        case "4": return .visa
        case "2", "5": return .mastercard
        case "6": return .himyan
        case "9": return .naps
        default: return nil
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .visa: return [Color(hex: 0x1A1F71), Color(hex: 0x3B4CCA)]
        case .mastercard: return [Color(hex: 0x1F1F23), Color(hex: 0x44444E)]
        case .himyan: return [Color(hex: 0x8A1538), Color(hex: 0xB03A5B)]
        case .naps: return [Color(hex: 0x00594C), Color(hex: 0x00897B)]
        }
    }
}

/// A stored payment card (Visa/Mastercard only — local debit goes through QPay).
struct PaymentCard: Identifiable, Hashable {
    let id: UUID
    var brand: CardBrand
    var holderName: String
    /// Digits only, no spaces.
    var number: String
    var expiryMonth: Int
    var expiryYear: Int
    var isDefault: Bool

    var last4: String { String(number.suffix(4)) }
    var maskedNumber: String { "•••• \(last4)" }
    var displayName: String { "\(brand.rawValue) •••• \(last4)" }
    var expiryLabel: String { String(format: "%02d/%02d", expiryMonth, expiryYear % 100) }

    var isExpired: Bool {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        return expiryYear < year || (expiryYear == year && expiryMonth < month)
    }
}

struct Payout: Identifiable, Hashable {
    let id: UUID
    var dateLabel: String
    var amount: Double
    var status: String
}

struct SearchQuery: Hashable {
    var duration: ParkingDuration = .hourly
    var location: String = ""
    var startDate: Date
    var endDate: Date
    var fromTime: Date
    var toTime: Date

    init() {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let nextHour = calendar.date(bySettingHour: min(hour + 1, 23), minute: 0, second: 0, of: now) ?? now
        startDate = now
        endDate = calendar.date(byAdding: .day, value: 2, to: now) ?? now
        fromTime = nextHour
        toTime = calendar.date(byAdding: .hour, value: 4, to: nextHour) ?? nextHour
    }

    // MARK: - Formatting

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static func label(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        return dayFormatter.string(from: date)
    }

    var dateLabel: String { Self.label(for: startDate) }
    var endDateLabel: String { Self.label(for: endDate) }
    var fromTimeLabel: String { Self.timeFormatter.string(from: fromTime) }
    var toTimeLabel: String { Self.timeFormatter.string(from: toTime) }

    /// Whole hours between from/to, minimum 1.
    var hourCount: Int {
        max(1, Int((toTime.timeIntervalSince(fromTime) / 3600).rounded()))
    }

    /// Whole days between start/end, minimum 1.
    var dayCount: Int {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: startDate), to: Calendar.current.startOfDay(for: endDate)).day ?? 1
        return max(1, days)
    }

    var durationNote: String {
        switch duration {
        case .hourly: return "for \(hourCount) hour\(hourCount == 1 ? "" : "s")"
        case .daily: return "for \(dayCount) day\(dayCount == 1 ? "" : "s")"
        }
    }

    /// Compact schedule summary, e.g. "Today · 11:00 AM – 3:00 PM".
    var scheduleSummary: String {
        switch duration {
        case .hourly: return "\(dateLabel) · \(fromTimeLabel) – \(toTimeLabel)"
        case .daily: return "\(dateLabel) → \(endDateLabel)"
        }
    }

    func totalPrice(for spot: ParkingSpot) -> Double {
        switch duration {
        case .hourly: return (spot.pricePerHour ?? 10) * Double(hourCount)
        case .daily: return (spot.pricePerDay ?? 50) * Double(dayCount)
        }
    }
}
