import SwiftUI

/// Hero schedule card used on the security check-in screen so the officer can read the
/// booked window, the real gate stamps, the check-out countdown and any delay at a glance.
struct CheckInScheduleCard: View {
    let reservation: Reservation

    @State private var appeared: Bool = false
    @State private var pulse: Bool = false

    private var state: SecurityCheckState { reservation.securityState }

    private var isMultiDay: Bool { reservation.endDateLabel != nil }

    private var timeWindow: (start: String, end: String)? {
        if let start = reservation.startTime, let end = reservation.endTime {
            return (start, end)
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 14)

            divider

            scheduleBody
                .padding(.horizontal, 18)
                .padding(.vertical, 18)

            if reservation.checkedInAtLabel != nil || reservation.checkedOutAtLabel != nil {
                divider
                stamps
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
            }

            footer
        }
        .background(
            LinearGradient(
                colors: [Color(hex: 0x1F2937), Color.inkPrimary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(state.needsAttention ? state.tint.opacity(0.75) : Color.brandOrange.opacity(0.35), lineWidth: 1.5)
        )
        .shadow(color: Color.inkPrimary.opacity(0.22), radius: 16, y: 8)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 18)
        .scaleEffect(appeared ? 1 : 0.97)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.1)) {
                appeared = true
            }
            pulse = true
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.16))
            .frame(height: 1)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.brandOrange)

            Text("DATE & TIME")
                .font(.system(size: 12, weight: .heavy))
                .kerning(1.4)
                .foregroundStyle(.white.opacity(0.85))

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: state.icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(state.tint)
                    .scaleEffect(state.isInside && pulse ? 1.12 : 1)
                    .animation(
                        state == .overstay
                            ? .easeInOut(duration: 0.75).repeatForever(autoreverses: true)
                            : .default,
                        value: pulse
                    )
                Text(state.rawValue.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .kerning(0.6)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(state.needsAttention ? state.tint.opacity(0.28) : Color.white.opacity(0.14))
            .clipShape(.capsule)
        }
    }

    // MARK: - Booked window

    private var scheduleBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isMultiDay, let endDate = reservation.endDateLabel {
                HStack(alignment: .center, spacing: 12) {
                    dateBlock(caption: "FROM", value: reservation.dateLabel)
                    arrowDivider
                    dateBlock(caption: "TO", value: endDate)
                }
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    caption("DATE")
                    Text(reservation.dateLabel)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            if let window = timeWindow {
                HStack(alignment: .center, spacing: 12) {
                    timeBlock(caption: "CHECK IN", value: window.start, tint: Color.brandOrange)
                    arrowDivider
                    timeBlock(
                        caption: "CHECK OUT",
                        value: window.end,
                        tint: state == .overstay ? Color.failureRed : .white
                    )
                }
            }
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .kerning(1)
            .foregroundStyle(.white.opacity(0.55))
    }

    private func dateBlock(caption label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            caption(label)
            Text(value)
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timeBlock(caption label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            caption(label)
            Text(value)
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var arrowDivider: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white.opacity(0.6))
            .frame(width: 26, height: 26)
            .background(Color.white.opacity(0.12))
            .clipShape(.circle)
    }

    // MARK: - Real gate stamps

    private var stamps: some View {
        HStack(alignment: .center, spacing: 12) {
            stamp(
                icon: "arrow.down.to.line",
                label: "ARRIVED",
                value: reservation.checkedInAtLabel ?? "—",
                tint: Color.successGreen
            )

            Rectangle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 1, height: 34)

            stamp(
                icon: "arrow.up.right",
                label: "LEFT",
                value: reservation.checkedOutAtLabel ?? "Still inside",
                tint: reservation.checkedOutAtLabel == nil ? Color.brandOrange : Color.infoBlue
            )
        }
    }

    private func stamp(icon: String, label: String, value: String, tint: Color) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.18))
                .clipShape(.circle)
            VStack(alignment: .leading, spacing: 1) {
                caption(label)
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: "hourglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.brandOrange)
            Text(reservation.bookedDurationLabel)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
            Text("booked")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))

            Spacer(minLength: 8)

            if let delay = reservation.delayLabel {
                chip(icon: "exclamationmark.triangle.fill", text: delay, background: state.tint, foreground: .white)
            } else if let countdown = reservation.checkOutCountdownLabel {
                chip(icon: "timer", text: "\(countdown) left", background: Color.brandOrange, foreground: Color.inkPrimary)
            } else if state.isClosed {
                chip(icon: "checkmark", text: "Closed", background: Color.white.opacity(0.16), foreground: .white)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .background(Color.black.opacity(0.22))
    }

    private func chip(icon: String, text: String, background: Color, foreground: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(size: 13, weight: .bold))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(background)
        .clipShape(.capsule)
    }
}

/// Amber / red banner shown above the actions when a stay is late or overstaying.
struct CheckDelayBanner: View {
    let reservation: Reservation

    @State private var appeared: Bool = false

    private var state: SecurityCheckState { reservation.securityState }

    private var title: String {
        switch state {
        case .lateArrival: return "Guest is running late"
        case .overstay: return "Vehicle is overstaying"
        case .checkedOutLate: return "Closed after the booked window"
        default: return ""
        }
    }

    private var message: String {
        switch state {
        case .lateArrival:
            return "The booked window started \(Reservation.minutesLabel(reservation.lateArrivalMinutes)) ago and the car has not arrived. The spot stays reserved."
        case .overstay:
            let fee = reservation.overstayFee.map { " An extra \(Int($0)) QAR overstay fee applies." } ?? ""
            return "Booked check-out was \(Reservation.minutesLabel(reservation.overstayMinutes)) ago.\(fee)"
        case .checkedOutLate:
            let fee = reservation.overstayFee.map { " \(Int($0)) QAR overstay fee was charged." } ?? ""
            return "The guest left \(Reservation.minutesLabel(reservation.overstayMinutes)) past the booked check-out.\(fee)"
        default:
            return ""
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: state.icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(state.tint)
                .clipShape(.circle)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.inkPrimary)
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(state.tint.opacity(0.1))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(state.tint.opacity(0.35), lineWidth: 1.5)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
        }
    }
}
