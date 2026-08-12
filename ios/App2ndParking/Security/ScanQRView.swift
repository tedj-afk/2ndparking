import SwiftUI

/// Mock QR scanner: pick Check-in or Check-out, tap the frame to "scan" the next
/// matching guest, then verify and stamp the gate event.
struct ScanQRView: View {
    enum Phase: Hashable {
        case scanning
        case processing
        case completed
        case failed
    }

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// Preselects the gate action (e.g. tapping the "Vehicles inside" chip opens check-out).
    var initialMode: GateMode = .checkIn

    @State private var mode: GateMode = .checkIn
    @State private var phase: Phase = .scanning
    @State private var scannedReservationID: UUID?
    @State private var scanLineDown: Bool = false

    /// Next reservation the officer would realistically scan for the selected action.
    private var nextMatch: Reservation? {
        switch mode {
        case .checkIn:
            return store.reservations.first { $0.securityState == .lateArrival }
                ?? store.reservations.first { $0.canCheckIn && $0.status == .upcoming }
                ?? store.reservations.first(where: \.canCheckIn)
        case .checkOut:
            return store.reservations.first { $0.securityState == .overstay }
                ?? store.reservations.first(where: \.canCheckOut)
        }
    }

    private var accent: Color {
        mode == .checkIn ? .brandOrange : .infoBlue
    }

    var body: some View {
        Group {
            switch phase {
            case .scanning:
                scanner
            case .processing:
                ProcessingView(
                    title: mode == .checkIn ? "Processing Verification" : "Processing Check-Out",
                    message: mode == .checkIn
                        ? "Checking the reservation, vehicle and access permissions."
                        : "Closing the stay and releasing the spot."
                )
                .task {
                    try? await Task.sleep(for: .seconds(1.8))
                    if store.simulateFailures {
                        phase = .failed
                    } else if let match = nextMatch {
                        scannedReservationID = match.id
                        switch mode {
                        case .checkIn: store.checkIn(reservationID: match.id)
                        case .checkOut: store.checkOut(reservationID: match.id)
                        }
                        phase = .completed
                    } else {
                        phase = .failed
                    }
                }
            case .completed:
                if let id = scannedReservationID, let reservation = store.reservation(id: id) {
                    GateResultView(reservation: reservation, mode: mode) {
                        dismiss()
                    }
                }
            case .failed:
                ResultView(
                    isSuccess: false,
                    title: "Verification Failed",
                    message: mode == .checkIn
                        ? "This QR code doesn't match an active reservation for this building. Ask the guest to open their Access Pass and try again."
                        : "No vehicle inside the garage matches this QR code. Check the plate number in the check-ins list instead.",
                    primaryTitle: "Scan Again",
                    primaryAction: { phase = .scanning },
                    linkTitle: "Close",
                    linkAction: { dismiss() }
                )
            }
        }
        .background(Color.white)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: phase)
        .onAppear { mode = initialMode }
    }

    private var scanner: some View {
        VStack(spacing: 0) {
            TopBar(leadingIcon: "xmark", onLeading: { dismiss() })

            Text(mode == .checkIn ? "Scan QR code to Check-in" : "Scan QR code to Check-out")
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .contentTransition(.opacity)

            modePicker
                .padding(.top, 16)

            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                phase = .processing
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.inkPrimary.opacity(0.92))

                    VStack(spacing: 16) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 64))
                            .foregroundStyle(.white.opacity(0.55))
                        Text("Camera preview (mock)")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.5))
                        Text("Tap to simulate a scan")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(accent)
                    }

                    GeometryReader { geo in
                        Rectangle()
                            .fill(accent.opacity(0.85))
                            .frame(height: 2.5)
                            .shadow(color: accent, radius: 6)
                            .offset(y: scanLineDown ? geo.size.height - 40 : 40)
                            .padding(.horizontal, 30)
                            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: scanLineDown)
                    }

                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1.5)
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .onAppear { scanLineDown = true }

            hint
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
        }
    }

    private var modePicker: some View {
        HStack(spacing: 6) {
            modeButton(.checkIn, title: "Check-in", icon: "arrow.down.to.line")
            modeButton(.checkOut, title: "Check-out", icon: "arrow.up.right")
        }
        .padding(5)
        .background(Color.fieldGray)
        .clipShape(.capsule)
    }

    private func modeButton(_ value: GateMode, title: String, icon: String) -> some View {
        let isSelected = mode == value
        return Button {
            guard !isSelected else { return }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                mode = value
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(isSelected ? .white : Color.inkSecondary)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(isSelected ? (value == .checkIn ? Color.brandOrange : Color.infoBlue) : .clear)
            .clipShape(.capsule)
        }
    }

    @ViewBuilder
    private var hint: some View {
        if mode == .checkIn {
            Text("Ask the guest to open their Access Pass in the 2ndParking app and hold the QR code inside the frame")
                .font(.system(size: 14))
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
        } else {
            VStack(spacing: 10) {
                Text("Scan the guest's Access Pass on the way out to release the spot and close the stay")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.inkSecondary)
                    .multilineTextAlignment(.center)

                if let next = nextMatch, next.securityState == .overstay, let delay = next.delayLabel {
                    HStack(spacing: 7) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("\(next.plateNumber) is \(delay)")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(Color.failureRed)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.failureRed.opacity(0.1))
                    .clipShape(.capsule)
                }
            }
        }
    }
}
