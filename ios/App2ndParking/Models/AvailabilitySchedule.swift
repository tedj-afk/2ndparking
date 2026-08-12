import SwiftUI

/// Days of the week, Sunday-first (the Qatari work week runs Sunday → Thursday).
enum Weekday: Int, CaseIterable, Identifiable, Comparable, Hashable {
    case sunday = 0, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool { lhs.rawValue < rhs.rawValue }

    var shortLabel: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    var fullLabel: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    var letter: String { String(shortLabel.prefix(1)) }

    /// Qatar's weekend is Friday + Saturday.
    var isWeekend: Bool { self == .friday || self == .saturday }

    static func from(_ date: Date) -> Weekday {
        let component = Calendar.current.component(.weekday, from: date)
        return Weekday(rawValue: component - 1) ?? .sunday
    }
}

/// One-tap availability templates offered in the lister editor.
enum SchedulePreset: String, CaseIterable, Identifiable {
    case workHours = "Work hours"
    case evenings = "Evenings"
    case weekends = "Weekends"
    case allDay = "24/7"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .workHours: return "briefcase.fill"
        case .evenings: return "moon.stars.fill"
        case .weekends: return "beach.umbrella.fill"
        case .allDay: return "infinity"
        }
    }

    var detail: String {
        switch self {
        case .workHours: return "Sun–Thu, 8:00 AM – 5:00 PM"
        case .evenings: return "Sun–Thu, 6:00 PM – 7:00 AM"
        case .weekends: return "Fri–Sat, all day"
        case .allDay: return "Every day, all day"
        }
    }
}

/// Weekly availability rules a lister sets for one spot: opening hours per weekday,
/// which days accept full-day stays, night limits, and one-off blocked dates.
struct AvailabilitySchedule: Hashable {
    /// Opening window for a single weekday. Minutes are counted from midnight;
    /// `closeMinutes` smaller than `openMinutes` means the window runs overnight.
    struct DayWindow: Hashable {
        var isOpen: Bool
        var openMinutes: Int
        var closeMinutes: Int

        static let closed = DayWindow(isOpen: false, openMinutes: 8 * 60, closeMinutes: 17 * 60)
        static let allDay = DayWindow(isOpen: true, openMinutes: 0, closeMinutes: 24 * 60)

        var isAllDay: Bool { isOpen && openMinutes == 0 && closeMinutes >= 24 * 60 }
        var isOvernight: Bool { isOpen && closeMinutes < openMinutes }

        var rangeLabel: String {
            guard isOpen else { return "Closed" }
            if isAllDay { return "All day" }
            return "\(AvailabilitySchedule.timeLabel(openMinutes)) – \(AvailabilitySchedule.timeLabel(closeMinutes))"
        }

        /// True when a booking from/to (minutes from midnight) fits inside this window.
        func covers(fromMinutes: Int, toMinutes: Int) -> Bool {
            guard isOpen else { return false }
            if isAllDay { return true }
            if isOvernight {
                if toMinutes <= fromMinutes { // booking also wraps past midnight
                    return fromMinutes >= openMinutes && toMinutes <= closeMinutes
                }
                return (fromMinutes >= openMinutes) || (toMinutes <= closeMinutes && fromMinutes >= 0)
            }
            guard toMinutes > fromMinutes else { return false }
            return fromMinutes >= openMinutes && toMinutes <= closeMinutes
        }
    }

    /// Accepts hourly bookings.
    var allowsHourly: Bool = true
    /// Accepts full-day (daily) bookings.
    var allowsDaily: Bool = true
    /// Seven windows, Sunday-first.
    var windows: [DayWindow] = Array(repeating: .allDay, count: 7)
    /// Weekdays a full-day stay may cover.
    var dailyDays: Set<Weekday> = Set(Weekday.allCases)
    var minNights: Int = 1
    var maxNights: Int = 30
    /// One-off dates the spot is unavailable (normalized to start of day).
    var blockedDates: Set<Date> = []
    /// Temporarily stops all new bookings without archiving the listing.
    var isPaused: Bool = false

    // MARK: - Presets

    static let alwaysOpen = AvailabilitySchedule()

    /// Weekday work hours — the classic "my car is at the office 8-to-5" case.
    static func workHours(open: Int = 8 * 60, close: Int = 17 * 60) -> AvailabilitySchedule {
        var schedule = AvailabilitySchedule()
        schedule.windows = Weekday.allCases.map { day in
            day.isWeekend ? .closed : DayWindow(isOpen: true, openMinutes: open, closeMinutes: close)
        }
        schedule.dailyDays = Set(Weekday.allCases.filter { !$0.isWeekend })
        schedule.maxNights = 5
        return schedule
    }

    static func preset(_ preset: SchedulePreset) -> AvailabilitySchedule {
        switch preset {
        case .workHours:
            return workHours()
        case .evenings:
            var schedule = AvailabilitySchedule()
            schedule.windows = Weekday.allCases.map { day in
                day.isWeekend ? .closed : DayWindow(isOpen: true, openMinutes: 18 * 60, closeMinutes: 7 * 60)
            }
            schedule.dailyDays = []
            schedule.allowsDaily = false
            return schedule
        case .weekends:
            var schedule = AvailabilitySchedule()
            schedule.windows = Weekday.allCases.map { day in day.isWeekend ? .allDay : .closed }
            schedule.dailyDays = Set(Weekday.allCases.filter(\.isWeekend))
            schedule.maxNights = 2
            return schedule
        case .allDay:
            return alwaysOpen
        }
    }

    /// The preset this schedule matches, or nil when the lister customised it.
    var matchedPreset: SchedulePreset? {
        SchedulePreset.allCases.first { preset in
            AvailabilitySchedule.preset(preset).windows == windows
        }
    }

    // MARK: - Day access

    func window(for day: Weekday) -> DayWindow {
        windows.indices.contains(day.rawValue) ? windows[day.rawValue] : .allDay
    }

    mutating func setWindow(_ window: DayWindow, for day: Weekday) {
        guard windows.indices.contains(day.rawValue) else { return }
        windows[day.rawValue] = window
    }

    /// Copies one day's hours onto every other open day.
    mutating func applyHoursToAllOpenDays(from day: Weekday) {
        let source = window(for: day)
        for target in Weekday.allCases where window(for: target).isOpen {
            setWindow(DayWindow(isOpen: true, openMinutes: source.openMinutes, closeMinutes: source.closeMinutes), for: target)
        }
    }

    var openDays: [Weekday] { Weekday.allCases.filter { window(for: $0).isOpen } }
    var closedDays: [Weekday] { Weekday.allCases.filter { !window(for: $0).isOpen } }
    var isWeekendClosed: Bool { Weekday.allCases.filter(\.isWeekend).allSatisfy { !window(for: $0).isOpen } }
    var hasNoOpenDays: Bool { openDays.isEmpty }

    // MARK: - Summaries

    /// Open days grouped into runs that share the same hours, e.g. [Sun–Thu 8–5].
    var hourGroups: [(days: [Weekday], window: DayWindow)] {
        var groups: [(days: [Weekday], window: DayWindow)] = []
        for day in Weekday.allCases {
            let current = window(for: day)
            guard current.isOpen else { continue }
            if var last = groups.last,
               last.window.openMinutes == current.openMinutes,
               last.window.closeMinutes == current.closeMinutes,
               let previous = last.days.last,
               previous.rawValue == day.rawValue - 1 {
                last.days.append(day)
                groups[groups.count - 1] = last
            } else {
                groups.append((days: [day], window: current))
            }
        }
        return groups
    }

    /// "Sun–Thu" for runs, "Sun, Tue" for gaps.
    static func daysLabel(_ days: [Weekday]) -> String {
        guard let first = days.first, let last = days.last else { return "—" }
        if days.count == 1 { return first.shortLabel }
        if days.count == 7 { return "Every day" }
        let isRun = days.enumerated().allSatisfy { index, day in day.rawValue == first.rawValue + index }
        return isRun ? "\(first.shortLabel)–\(last.shortLabel)" : days.map(\.shortLabel).joined(separator: ", ")
    }

    /// One-line label for detail rows and cards, e.g. "Sun–Thu · 8:00 AM – 5:00 PM".
    var compactSummary: String {
        if isPaused { return "Paused" }
        if hasNoOpenDays { return "No availability set" }
        if windows.allSatisfy(\.isAllDay) { return "24/7" }
        let parts = hourGroups.map { group in
            "\(AvailabilitySchedule.daysLabel(group.days)) · \(group.window.rangeLabel)"
        }
        guard parts.count > 2 else { return parts.joined(separator: "  •  ") }
        return parts.prefix(2).joined(separator: "  •  ") + " +\(parts.count - 2)"
    }

    /// Days-only label used on cards, e.g. "Open Sun–Thu".
    var openDaysSummary: String {
        if hasNoOpenDays { return "No open days" }
        if openDays.count == 7 { return "Open every day" }
        return "Open \(AvailabilitySchedule.daysLabel(openDays))"
    }

    /// Full-day rules label, e.g. "Full days Sun–Thu · 1–5 nights".
    var dailySummary: String {
        guard allowsDaily else { return "Full-day stays off" }
        guard !dailyDays.isEmpty else { return "No full-day coverage" }
        let days = AvailabilitySchedule.daysLabel(Weekday.allCases.filter { dailyDays.contains($0) })
        let nights = minNights == maxNights
            ? "\(minNights) night\(minNights == 1 ? "" : "s")"
            : "\(minNights)–\(maxNights) nights"
        return "\(days) · \(nights)"
    }

    var blockedSummary: String? {
        guard !blockedDates.isEmpty else { return nil }
        return "\(blockedDates.count) date\(blockedDates.count == 1 ? "" : "s") blocked"
    }

    /// Rental types the spot currently accepts.
    var offeredDurations: [ParkingDuration] {
        var result: [ParkingDuration] = []
        if allowsHourly { result.append(.hourly) }
        if allowsDaily { result.append(.daily) }
        return result
    }

    // MARK: - Blocked dates

    static func normalized(_ date: Date) -> Date { Calendar.current.startOfDay(for: date) }

    func isBlocked(_ date: Date) -> Bool { blockedDates.contains(AvailabilitySchedule.normalized(date)) }

    mutating func toggleBlocked(_ date: Date) {
        let key = AvailabilitySchedule.normalized(date)
        if blockedDates.contains(key) {
            blockedDates.remove(key)
        } else {
            blockedDates.insert(key)
        }
    }

    // MARK: - Matching a search

    /// Result of testing a search request against these rules.
    struct Check: Hashable {
        var isAvailable: Bool
        /// Short reason shown on cards / pills, e.g. "Closed Friday".
        var title: String?
        /// Sentence shown in banners explaining what the renter should do.
        var message: String?

        static let available = Check(isAvailable: true, title: nil, message: nil)

        static func blocked(_ title: String, _ message: String) -> Check {
            Check(isAvailable: false, title: title, message: message)
        }
    }

    func check(_ query: SearchQuery) -> Check {
        if isPaused {
            return .blocked("Bookings paused", "The owner paused this spot. Try again later or pick another spot nearby.")
        }
        switch query.duration {
        case .hourly:
            guard allowsHourly else {
                return .blocked("Hourly unavailable", "This spot is only offered for full-day stays.")
            }
            let day = Weekday.from(query.startDate)
            if isBlocked(query.startDate) {
                return .blocked("Blocked on \(query.dateLabel)", "The owner blocked \(query.dateLabel) for personal use. Pick another date.")
            }
            let window = window(for: day)
            guard window.isOpen else {
                return .blocked("Closed \(day.shortLabel)", "The owner keeps the spot on \(day.fullLabel). \(openDaysSummary) — \(compactSummary).")
            }
            let from = AvailabilitySchedule.minutes(of: query.fromTime)
            let to = AvailabilitySchedule.minutes(of: query.toTime)
            guard window.covers(fromMinutes: from, toMinutes: to) else {
                return .blocked(
                    "Outside opening hours",
                    "On \(day.fullLabel) this spot is available \(window.rangeLabel). Adjust your times to fit."
                )
            }
            return .available
        case .daily:
            guard allowsDaily else {
                return .blocked("Full days unavailable", "This spot is only offered by the hour.")
            }
            let nights = query.dayCount
            if nights < minNights {
                return .blocked("Minimum \(minNights) nights", "The owner accepts stays of at least \(minNights) night\(minNights == 1 ? "" : "s"). Extend your dates.")
            }
            if nights > maxNights {
                return .blocked("Maximum \(maxNights) nights", "The owner accepts stays up to \(maxNights) nights. Shorten your dates.")
            }
            let calendar = Calendar.current
            var cursor = calendar.startOfDay(for: query.startDate)
            let end = calendar.startOfDay(for: query.endDate)
            while cursor < end {
                let day = Weekday.from(cursor)
                if isBlocked(cursor) {
                    return .blocked("Blocked date in range", "The owner blocked \(AvailabilitySchedule.dateLabel(cursor)) inside your stay. Pick different dates.")
                }
                if !dailyDays.contains(day) {
                    return .blocked("Closed \(day.shortLabel)", "Full-day stays can't cover \(day.fullLabel) here. Available: \(dailySummary).")
                }
                guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
                cursor = next
            }
            return .available
        }
    }

    // MARK: - Formatting helpers

    static func minutes(of date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    /// Builds a Date for a picker bound to minutes-from-midnight.
    static func date(fromMinutes minutes: Int) -> Date {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: .now)
        return calendar.date(byAdding: .minute, value: min(minutes, 24 * 60 - 1), to: base) ?? base
    }

    /// "8:00 AM", with 24:00 rendered as "Midnight".
    static func timeLabel(_ minutes: Int) -> String {
        if minutes >= 24 * 60 { return "Midnight" }
        let hour24 = minutes / 60
        let minute = minutes % 60
        let suffix = hour24 >= 12 ? "PM" : "AM"
        var hour12 = hour24 % 12
        if hour12 == 0 { hour12 = 12 }
        return String(format: "%d:%02d %@", hour12, minute, suffix)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        return formatter
    }()

    static func dateLabel(_ date: Date) -> String { dateFormatter.string(from: date) }
}
