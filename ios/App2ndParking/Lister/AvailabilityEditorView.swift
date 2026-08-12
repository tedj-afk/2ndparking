import SwiftUI

/// Sheet wrapper around the availability form: edit, see clashes, then save.
struct AvailabilityEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let spotID: UUID

    @State private var draft: AvailabilitySchedule = .alwaysOpen
    @State private var isLoaded: Bool = false

    private var conflicts: [Reservation] {
        store.conflicts(for: spotID, schedule: draft)
    }

    private var isValid: Bool {
        guard draft.allowsHourly || draft.allowsDaily else { return false }
        if draft.allowsHourly && draft.hasNoOpenDays { return false }
        if draft.allowsDaily && draft.dailyDays.isEmpty { return false }
        return true
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(leadingIcon: "xmark", onLeading: { dismiss() }, title: "Availability")

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    AvailabilityForm(schedule: $draft)

                    if !conflicts.isEmpty {
                        conflictNotice
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 26)
            }

            VStack(spacing: 8) {
                Divider().overlay(Color.borderGray.opacity(0.5))
                if !isValid {
                    Text("Keep at least one rental type with one open day.")
                        .font(.helperText)
                        .foregroundStyle(Color.inkTertiary)
                }
                PrimaryButton(title: "Save Availability", isEnabled: isValid) {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    store.updateSchedule(spotID: spotID, schedule: draft)
                    dismiss()
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 6)
            .padding(.bottom, 8)
            .background(Color.white)
        }
        .background(Color.white)
        .onAppear {
            guard !isLoaded, let spot = store.spot(id: spotID) else { return }
            draft = spot.schedule
            isLoaded = true
        }
    }

    /// Warns the lister when saved bookings fall outside the new rules.
    private var conflictNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 9) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.pendingAmber)
                Text("\(conflicts.count) booked stay\(conflicts.count == 1 ? "" : "s") fall outside these hours")
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundStyle(Color.inkPrimary)
            }
            ForEach(conflicts) { reservation in
                Text("• \(reservation.guestName) — \(reservation.dateLabel)\(reservation.startTime.map { ", \($0)" } ?? "")")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSecondary)
            }
            Text("Existing bookings stay valid. The new rules only apply to future requests.")
                .font(.system(size: 12.5))
                .foregroundStyle(Color.inkTertiary)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.pendingAmber.opacity(0.12))
        .clipShape(.rect(cornerRadius: 14))
    }
}

/// The reusable availability form — presets, rental types, weekly hours,
/// full-day rules and blocked dates. Used in the sheet and in the add-listing wizard.
struct AvailabilityForm: View {
    @Binding var schedule: AvailabilitySchedule

    /// Day currently expanded for time editing.
    @State private var expandedDay: Weekday?

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            presetsSection
            rentalTypesSection
            if schedule.allowsHourly {
                weeklyHoursSection
            }
            if schedule.allowsDaily {
                fullDaySection
            }
            blockedDatesSection
            pauseSection
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: schedule)
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: expandedDay)
    }

    // MARK: - Presets

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Quick setup")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SchedulePreset.allCases) { preset in
                        presetCard(preset)
                    }
                }
            }
            .scrollClipDisabled()
        }
    }

    private func presetCard(_ preset: SchedulePreset) -> some View {
        let isActive = schedule.matchedPreset == preset
        return Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                let template = AvailabilitySchedule.preset(preset)
                schedule.windows = template.windows
                schedule.dailyDays = template.dailyDays
                schedule.maxNights = template.maxNights
                if !template.allowsDaily { schedule.allowsDaily = false }
                expandedDay = nil
            }
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                Image(systemName: preset.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isActive ? .white : Color.brandOrange)
                Text(preset.rawValue)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isActive ? .white : Color.inkPrimary)
                Text(preset.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(isActive ? .white.opacity(0.8) : Color.inkSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(width: 156, alignment: .leading)
            .padding(13)
            .background(isActive ? Color.inkPrimary : Color.cardGray)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isActive ? Color.brandOrange : Color.clear, lineWidth: 1.6)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Rental types

    private var rentalTypesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Rental types")
            ToggleRow(label: "Hourly bookings", isOn: $schedule.allowsHourly)
            ToggleRow(label: "Full-day bookings", isOn: $schedule.allowsDaily)
            if !schedule.allowsHourly && !schedule.allowsDaily {
                Text("Turn on at least one rental type.")
                    .font(.helperText)
                    .foregroundStyle(Color.failureRed)
            }
        }
    }

    // MARK: - Weekly hours

    private var weeklyHoursSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(title: "Weekly hours")
                Button(schedule.isWeekendClosed ? "Open weekend" : "Close weekend") {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        let shouldOpen = schedule.isWeekendClosed
                        let reference = schedule.openDays.first.map { schedule.window(for: $0) } ?? .allDay
                        for day in Weekday.allCases where day.isWeekend {
                            schedule.setWindow(
                                shouldOpen
                                    ? AvailabilitySchedule.DayWindow(isOpen: true, openMinutes: reference.openMinutes, closeMinutes: reference.closeMinutes)
                                    : .closed,
                                for: day
                            )
                            if shouldOpen {
                                schedule.dailyDays.insert(day)
                            } else {
                                schedule.dailyDays.remove(day)
                            }
                        }
                    }
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.brandOrange)
                .fixedSize()
            }

            Text(schedule.hasNoOpenDays ? "Pick the days your spot is free." : schedule.compactSummary)
                .font(.system(size: 13))
                .foregroundStyle(schedule.hasNoOpenDays ? Color.failureRed : Color.inkSecondary)

            VStack(spacing: 8) {
                ForEach(Weekday.allCases) { day in
                    DayHoursRow(
                        day: day,
                        window: $schedule.windows[day.rawValue],
                        isExpanded: expandedDay == day,
                        onToggleExpand: {
                            expandedDay = expandedDay == day ? nil : day
                        },
                        onApplyToAll: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            schedule.applyHoursToAllOpenDays(from: day)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Full-day rules

    private var fullDaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Full-day stays")
            Text("Pick the days a full-day booking may cover, then set how long a stay can run.")
                .font(.system(size: 13))
                .foregroundStyle(Color.inkSecondary)

            HStack(spacing: 6) {
                ForEach(Weekday.allCases) { day in
                    dayToggle(day)
                }
            }

            VStack(spacing: 8) {
                nightStepper(title: "Minimum stay", value: $schedule.minNights, range: 1...schedule.maxNights)
                nightStepper(title: "Maximum stay", value: $schedule.maxNights, range: schedule.minNights...60)
            }

            if schedule.dailyDays.isEmpty {
                Text("Select at least one day for full-day stays.")
                    .font(.helperText)
                    .foregroundStyle(Color.failureRed)
            }
        }
    }

    private func dayToggle(_ day: Weekday) -> some View {
        let isOn = schedule.dailyDays.contains(day)
        return Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                if isOn { schedule.dailyDays.remove(day) } else { schedule.dailyDays.insert(day) }
            }
        } label: {
            VStack(spacing: 3) {
                Text(day.letter)
                    .font(.system(size: 14, weight: .bold))
                Text(day.shortLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .opacity(0.7)
            }
            .foregroundStyle(isOn ? .white : Color.inkTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isOn ? Color.brandOrange : Color.fieldGray)
            .clipShape(.rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func nightStepper(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.inkPrimary)
            Spacer()
            Stepper(value: value, in: range) {
                Text("\(value.wrappedValue) night\(value.wrappedValue == 1 ? "" : "s")")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.brandOrange)
                    .contentTransition(.numericText())
            }
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color.cardGray)
        .clipShape(.rect(cornerRadius: 14))
    }

    // MARK: - Blocked dates

    private var blockedDatesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(title: "Block specific dates")
                if !schedule.blockedDates.isEmpty {
                    Button("Clear all") {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            schedule.blockedDates.removeAll()
                        }
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.brandOrange)
                    .fixedSize()
                }
            }
            Text("Tap a date when you need the spot yourself — renters won't be able to book it.")
                .font(.system(size: 13))
                .foregroundStyle(Color.inkSecondary)

            BlockedDatesCalendar(schedule: $schedule)
        }
    }

    // MARK: - Pause

    private var pauseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ToggleRow(label: "Pause all new bookings", isOn: $schedule.isPaused)
            if schedule.isPaused {
                Text("Your listing stays visible but can't be booked until you resume it.")
                    .font(.helperText)
                    .foregroundStyle(Color.pendingAmber)
            }
        }
    }
}

/// One weekday row: open switch, hours summary, and expandable time pickers.
private struct DayHoursRow: View {
    let day: Weekday
    @Binding var window: AvailabilitySchedule.DayWindow
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onApplyToAll: () -> Void

    private var openBinding: Binding<Date> {
        Binding(
            get: { AvailabilitySchedule.date(fromMinutes: window.openMinutes) },
            set: { window.openMinutes = AvailabilitySchedule.minutes(of: $0) }
        )
    }

    private var closeBinding: Binding<Date> {
        Binding(
            get: { AvailabilitySchedule.date(fromMinutes: min(window.closeMinutes, 23 * 60 + 59)) },
            set: { window.closeMinutes = AvailabilitySchedule.minutes(of: $0) }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(day.shortLabel)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(window.isOpen ? Color.inkPrimary : Color.inkTertiary)
                    .frame(width: 38, alignment: .leading)

                Button {
                    guard window.isOpen else { return }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onToggleExpand()
                } label: {
                    HStack(spacing: 6) {
                        Text(window.rangeLabel)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(window.isOpen ? Color.inkPrimary : Color.inkTertiary)
                        if window.isOpen {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.inkSecondary)
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)

                Toggle("", isOn: Binding(
                    get: { window.isOpen },
                    set: { newValue in
                        window.isOpen = newValue
                        if !newValue && isExpanded { onToggleExpand() }
                    }
                ))
                .labelsHidden()
                .tint(Color.brandOrange)
            }
            .padding(.horizontal, 14)
            .frame(height: 54)

            if isExpanded && window.isOpen {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        TimePickerField(label: "From", time: openBinding)
                        TimePickerField(label: "To", time: closeBinding)
                    }
                    HStack(spacing: 10) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                window = .allDay
                            }
                        } label: {
                            chip(icon: "infinity", title: "All day")
                        }
                        Button(action: onApplyToAll) {
                            chip(icon: "arrow.triangle.2.circlepath", title: "Apply to all open days")
                        }
                    }
                    if window.isOvernight {
                        Text("Overnight window — runs past midnight into the next morning.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.infoBlue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(window.isOpen ? Color.cardGray : Color.fieldGray.opacity(0.5))
        .clipShape(.rect(cornerRadius: 14))
    }

    private func chip(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .lineLimit(1)
        }
        .foregroundStyle(Color.brandOrange)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(Color.orangeFaint)
        .clipShape(.capsule)
    }
}

/// Month grid where the lister taps single dates to block or unblock them.
struct BlockedDatesCalendar: View {
    @Binding var schedule: AvailabilitySchedule

    @State private var monthAnchor: Date = Calendar.current.startOfDay(for: .now)

    private let calendar = Calendar.current

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: monthAnchor)
    }

    /// Leading blanks + every day of the displayed month.
    private var cells: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: monthAnchor) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: interval.start) - 1
        let dayCount = calendar.range(of: .day, in: .month, for: monthAnchor)?.count ?? 30
        var result: [Date?] = Array(repeating: nil, count: firstWeekday)
        for offset in 0..<dayCount {
            result.append(calendar.date(byAdding: .day, value: offset, to: interval.start))
        }
        return result
    }

    var body: some View {
        VStack(spacing: 12) {
            header

            HStack(spacing: 4) {
                ForEach(Weekday.allCases) { day in
                    Text(day.letter)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.inkTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(date)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }

            if let summary = schedule.blockedSummary {
                HStack(spacing: 7) {
                    Circle().fill(Color.failureRed).frame(width: 7, height: 7)
                    Text(summary)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.inkPrimary)
                    Spacer()
                }
            }
        }
        .padding(14)
        .background(Color.cardGray)
        .clipShape(.rect(cornerRadius: 16))
    }

    private var header: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(canGoBack ? Color.inkPrimary : Color.placeholderGray)
                    .frame(width: 32, height: 32)
                    .background(Color.white)
                    .clipShape(.circle)
            }
            .disabled(!canGoBack)

            Spacer()
            Text(monthLabel)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.inkPrimary)
                .contentTransition(.numericText())
            Spacer()

            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.inkPrimary)
                    .frame(width: 32, height: 32)
                    .background(Color.white)
                    .clipShape(.circle)
            }
        }
    }

    private var canGoBack: Bool {
        guard let previous = calendar.date(byAdding: .month, value: -1, to: monthAnchor) else { return false }
        return calendar.compare(previous, to: .now, toGranularity: .month) != .orderedAscending
    }

    private func shiftMonth(by value: Int) {
        guard let next = calendar.date(byAdding: .month, value: value, to: monthAnchor) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            monthAnchor = next
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let isPast = calendar.startOfDay(for: date) < calendar.startOfDay(for: .now)
        let isBlocked = schedule.isBlocked(date)
        let isClosed = !schedule.window(for: Weekday.from(date)).isOpen
        let isToday = calendar.isDateInToday(date)

        return Button {
            guard !isPast else { return }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                schedule.toggleBlocked(date)
            }
        } label: {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 14, weight: isBlocked || isToday ? .bold : .medium))
                .foregroundStyle(cellForeground(isPast: isPast, isBlocked: isBlocked, isClosed: isClosed))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(isBlocked ? Color.failureRed : (isClosed ? Color.fieldGray : Color.white))
                .clipShape(.rect(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isToday ? Color.brandOrange : Color.clear, lineWidth: 1.5)
                )
                .overlay(alignment: .bottom) {
                    if isBlocked {
                        Image(systemName: "slash.circle.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.bottom, 3)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(isPast)
    }

    private func cellForeground(isPast: Bool, isBlocked: Bool, isClosed: Bool) -> Color {
        if isBlocked { return .white }
        if isPast { return .placeholderGray }
        if isClosed { return .inkTertiary }
        return .inkPrimary
    }
}
