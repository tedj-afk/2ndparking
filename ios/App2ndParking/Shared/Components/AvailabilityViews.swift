import SwiftUI

/// Read-only weekly availability card: 7 day pills + the grouped hour lines.
/// Used on the renter spot detail and the lister listing detail.
struct AvailabilityWeekCard: View {
    let schedule: AvailabilitySchedule
    /// Highlights this weekday (e.g. the day the renter picked).
    var highlightedDay: Weekday? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                ForEach(Weekday.allCases) { day in
                    dayPill(day)
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                if schedule.hasNoOpenDays {
                    line(icon: "moon.zzz", text: "No hourly availability set", tint: .inkTertiary)
                } else {
                    ForEach(Array(schedule.hourGroups.enumerated()), id: \.offset) { _, group in
                        line(
                            icon: "clock",
                            text: "\(AvailabilitySchedule.daysLabel(group.days))  ·  \(group.window.rangeLabel)",
                            tint: .brandOrange
                        )
                    }
                }
                if !schedule.closedDays.isEmpty {
                    line(
                        icon: "xmark.circle",
                        text: "Closed \(AvailabilitySchedule.daysLabel(schedule.closedDays))",
                        tint: .inkTertiary
                    )
                }
                if schedule.allowsDaily {
                    line(icon: "sun.max", text: "Full days \(schedule.dailySummary)", tint: .infoBlue)
                }
                if let blocked = schedule.blockedSummary {
                    line(icon: "calendar.badge.minus", text: blocked, tint: .pendingAmber)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardGray)
        .clipShape(.rect(cornerRadius: 16))
    }

    private func dayPill(_ day: Weekday) -> some View {
        let window = schedule.window(for: day)
        let isHighlighted = highlightedDay == day
        return VStack(spacing: 5) {
            Text(day.letter)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(window.isOpen ? Color.inkPrimary : Color.inkTertiary)
            Circle()
                .fill(window.isOpen ? Color.brandOrange : Color.borderGray)
                .frame(width: 6, height: 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(window.isOpen ? Color.orangeFaint : Color.white.opacity(0.6))
        .clipShape(.rect(cornerRadius: 11))
        .overlay(
            RoundedRectangle(cornerRadius: 11)
                .strokeBorder(isHighlighted ? Color.inkPrimary : Color.clear, lineWidth: 1.6)
        )
    }

    private func line(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 18)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.inkPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

/// Amber banner explaining why a spot can't be booked for the selected dates/times.
struct AvailabilityNoticeBanner: View {
    let check: AvailabilitySchedule.Check
    var onAdjust: (() -> Void)? = nil

    var body: some View {
        if !check.isAvailable {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.pendingAmber)

                VStack(alignment: .leading, spacing: 3) {
                    Text(check.title ?? "Unavailable")
                        .font(.system(size: 14.5, weight: .bold))
                        .foregroundStyle(Color.inkPrimary)
                    if let message = check.message {
                        Text(message)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let onAdjust {
                        Button("Change dates & times", action: onAdjust)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.brandOrange)
                            .padding(.top, 2)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(13)
            .background(Color.pendingAmber.opacity(0.12))
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.pendingAmber.opacity(0.35), lineWidth: 1)
            )
        }
    }
}

/// Compact capsule showing an unavailability reason on a search result card.
struct AvailabilityPill: View {
    let text: String
    var tint: Color = .pendingAmber

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.12))
        .clipShape(.capsule)
    }
}
