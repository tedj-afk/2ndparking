import SwiftUI

/// Security home: gate log with filter tabs, live check-out countdowns, overstay alerts, scan FAB.
struct CheckInsView: View {
    @Environment(AppStore.self) private var store

    @Binding var path: [SecurityRoute]
    @Binding var showScanner: Bool

    @State private var filter: String = "All"
    @State private var scanMode: GateMode = .checkIn

    private let filters = ["All", "Inside", "Alerts", "Expected", "Closed"]

    private var relevant: [Reservation] {
        store.reservations.filter { $0.status != .cancelled && $0.status != .pending }
    }

    private var filtered: [Reservation] {
        switch filter {
        case "Inside":
            return relevant.filter { $0.securityState.isInside }.sorted { order(of: $0) < order(of: $1) }
        case "Alerts":
            return relevant.filter { $0.securityState.needsAttention }
        case "Expected":
            return relevant.filter { $0.securityState == .awaitingArrival }
        case "Closed":
            return relevant.filter { $0.securityState.isClosed }
        default:
            return relevant.sorted { order(of: $0) < order(of: $1) }
        }
    }

    /// Overstays first, then parked, late arrivals, expected, closed.
    private func order(of reservation: Reservation) -> Int {
        switch reservation.securityState {
        case .overstay: return 0
        case .parked: return 1
        case .lateArrival: return 2
        case .awaitingArrival: return 3
        case .checkedOutLate: return 4
        case .checkedOut: return 5
        }
    }

    private var insideCount: Int { relevant.filter { $0.securityState.isInside }.count }
    private var alertCount: Int { relevant.filter { $0.securityState.needsAttention }.count }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                HStack {
                    Text("Check-ins")
                        .font(.pageTitle)
                        .foregroundStyle(Color.inkPrimary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                summaryChips
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)

                FilterTabs(options: filters, selection: $filter)
                    .padding(.bottom, 12)

                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(filtered) { reservation in
                            Button {
                                path.append(.reservationDetail(reservation.id))
                            } label: {
                                ReservationCard(
                                    reservation: reservation,
                                    trailingName: reservation.guestName,
                                    showsSecurityState: true,
                                    showsPhoto: false
                                )
                                .overlay(alignment: .topLeading) {
                                    if reservation.securityState == .overstay {
                                        RoundedRectangle(cornerRadius: 18)
                                            .strokeBorder(Color.failureRed.opacity(0.45), lineWidth: 1.5)
                                    }
                                }
                            }
                            .opacity(reservation.securityState.isClosed ? 0.7 : 1)
                        }
                        if filtered.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "checkmark.shield")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color.placeholderGray)
                                Text(emptyMessage)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.inkSecondary)
                            }
                            .padding(.top, 70)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: filter)
            }

            FloatingActionButton(systemName: "qrcode.viewfinder") {
                scanMode = .checkIn
                showScanner = true
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showScanner) {
            ScanQRView(initialMode: scanMode)
        }
    }

    private var emptyMessage: String {
        switch filter {
        case "Inside": return "No vehicles inside right now"
        case "Alerts": return "No late arrivals or overstays"
        case "Expected": return "No guests expected"
        case "Closed": return "No closed stays yet"
        default: return "No check-ins in this filter"
        }
    }

    /// Two tappable stat chips: vehicles inside (opens check-out scan) and attention alerts.
    private var summaryChips: some View {
        HStack(spacing: 10) {
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                scanMode = .checkOut
                showScanner = true
            } label: {
                statChip(
                    icon: "car.fill",
                    value: "\(insideCount)",
                    title: "Inside",
                    caption: "Tap to check-out",
                    tint: .successGreen
                )
            }

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    filter = alertCount > 0 ? "Alerts" : "All"
                }
            } label: {
                statChip(
                    icon: "exclamationmark.triangle.fill",
                    value: "\(alertCount)",
                    title: alertCount == 1 ? "Alert" : "Alerts",
                    caption: alertCount > 0 ? "Needs attention" : "All clear",
                    tint: alertCount > 0 ? .failureRed : .inkTertiary
                )
            }
        }
    }

    private func statChip(icon: String, value: String, title: String, caption: String, tint: Color) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.14))
                .clipShape(.circle)

            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.inkPrimary)
                        .contentTransition(.numericText())
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.inkPrimary)
                }
                Text(caption)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(Color.cardGray)
        .clipShape(.rect(cornerRadius: 16))
    }
}
