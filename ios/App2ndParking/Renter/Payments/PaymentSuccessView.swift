import SwiftUI

/// Post-payment celebration screen: confetti burst, drawn checkmark,
/// and a staggered receipt card with the booking + payment details.
struct PaymentSuccessView: View {
    let record: PaymentRecord
    let reservation: Reservation?
    let onAccessPass: () -> Void
    let onViewReservation: () -> Void

    @State private var ringProgress: CGFloat = 0
    @State private var checkProgress: CGFloat = 0
    @State private var badgeScale: CGFloat = 0.4
    @State private var badgeShown: Bool = false
    @State private var haloPulse: Bool = false
    @State private var showTitle: Bool = false
    @State private var showReceipt: Bool = false
    @State private var showButtons: Bool = false
    @State private var confettiFired: Bool = false
    @State private var receiptPDF: URL? = nil

    /// Booking rows shown between the payment method and reference on the receipt.
    private var receiptExtraRows: [(String, String)] {
        guard let reservation else { return [] }
        return [
            ("Spot", "\(reservation.spot.spotCode) · \(reservation.spot.buildingName)"),
            ("Schedule", scheduleLabel(reservation)),
            ("Vehicle", "\(reservation.vehicleBrand) \(reservation.vehicleModel) · \(reservation.plateNumber)"),
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.successPale.opacity(0.65), Color.white, Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                checkmarkBadge
                    .padding(.bottom, 22)

                VStack(spacing: 6) {
                    Text("Payment Successful")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.inkPrimary)
                    Text("Your spot is booked and your access pass is ready.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 14)

                PaymentReceiptCard(
                    record: record,
                    durationLabel: reservation?.bookedDurationLabel,
                    extraRows: receiptExtraRows,
                    notchColor: Color(hex: 0xF4FBF6)
                )
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .opacity(showReceipt ? 1 : 0)
                .offset(y: showReceipt ? 0 : 26)
                .scaleEffect(showReceipt ? 1 : 0.96)

                Spacer(minLength: 16)

                VStack(spacing: 14) {
                    PrimaryButton(title: "Access Pass", action: onAccessPass)

                    if let receiptPDF {
                        ShareLink(
                            item: receiptPDF,
                            preview: SharePreview(
                                "2ndParking Receipt \(record.reference)",
                                image: Image(systemName: "doc.richtext")
                            )
                        ) {
                            HStack(spacing: 7) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Share Receipt (PDF)")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(Color.brandOrange)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.orangePale.opacity(0.55))
                            .clipShape(.capsule)
                            .overlay(
                                Capsule()
                                    .stroke(Color.brandOrange.opacity(0.35), lineWidth: 1.5)
                            )
                            .contentShape(.capsule)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        })
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }

                    TextLinkButton(title: "View Reservation", action: onViewReservation)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 18)
            }

            if confettiFired {
                ConfettiBurstView()
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
        .onAppear { runEntrance() }
    }

    private func scheduleLabel(_ reservation: Reservation) -> String {
        if let start = reservation.startTime, let end = reservation.endTime {
            return "\(reservation.dateLabel) · \(start)–\(end)"
        }
        if let endDate = reservation.endDateLabel {
            return "\(reservation.dateLabel) → \(endDate)"
        }
        return reservation.dateLabel
    }

    // MARK: - Checkmark badge

    private var checkmarkBadge: some View {
        ZStack {
            // Soft expanding halo rings.
            ForEach(0..<2, id: \.self) { index in
                Circle()
                    .stroke(Color.successGreen.opacity(0.25 - Double(index) * 0.1), lineWidth: 2)
                    .frame(width: 116, height: 116)
                    .scaleEffect(haloPulse ? 1.45 + CGFloat(index) * 0.28 : 0.9)
                    .opacity(haloPulse ? 0 : 0.9)
                    .animation(
                        .easeOut(duration: 1.8)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.5),
                        value: haloPulse
                    )
            }

            Circle()
                .fill(Color.successPale)
                .frame(width: 116, height: 116)
                .scaleEffect(badgeScale)
                .opacity(badgeShown ? 1 : 0)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(Color.successGreen, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 116, height: 116)
                .rotationEffect(.degrees(-90))

            CheckmarkShape()
                .trim(from: 0, to: checkProgress)
                .stroke(Color.successGreen, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                .frame(width: 54, height: 54)
        }
        .frame(height: 130)
    }

    // MARK: - Entrance choreography

    private func runEntrance() {
        guard !badgeShown else { return }
        badgeShown = true

        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
            badgeScale = 1
        }
        withAnimation(.easeOut(duration: 0.5)) {
            ringProgress = 1
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.35)) {
            checkProgress = 1
        }

        Task {
            try? await Task.sleep(for: .milliseconds(450))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            confettiFired = true
            haloPulse = true

            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                showTitle = true
            }
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                showReceipt = true
            }
            try? await Task.sleep(for: .milliseconds(220))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                showButtons = true
            }

            // Render the shareable PDF once the entrance has settled.
            if receiptPDF == nil {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    receiptPDF = ReceiptPDFExporter.generate(record: record, reservation: reservation)
                }
            }
        }
    }
}

// MARK: - Shapes

/// Tick mark drawn stroke-by-stroke via `.trim`.
private struct CheckmarkShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.05, y: rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.width * 0.38, y: rect.height * 0.86))
        path.addLine(to: CGPoint(x: rect.width * 0.95, y: rect.height * 0.16))
        return path
    }
}

// MARK: - Confetti

/// One-shot physics-based confetti burst rendered with Canvas + TimelineView.
private struct ConfettiBurstView: View {
    private struct Particle {
        let originX: CGFloat
        let velocityX: CGFloat
        let velocityY: CGFloat
        let spinSpeed: Double
        let size: CGFloat
        let color: Color
        let isCircle: Bool
        let delay: Double
    }

    private static let palette: [Color] = [
        .brandOrange, .successGreen, Color(hex: 0xFBBF24),
        Color(hex: 0x3B82F6), Color(hex: 0xEC4899), Color(hex: 0x8B5CF6),
    ]

    @State private var particles: [Particle] = (0..<70).map { index in
        Particle(
            originX: CGFloat.random(in: 0.06...0.94),
            velocityX: CGFloat.random(in: -60...60),
            velocityY: CGFloat.random(in: 260...620),
            spinSpeed: Double.random(in: 1.5...5.5) * (Bool.random() ? 1 : -1),
            size: CGFloat.random(in: 6...11),
            color: palette[index % palette.count],
            isCircle: index % 4 == 0,
            delay: Double.random(in: 0...0.25)
        )
    }
    @State private var startDate: Date = .now

    private static let duration: Double = 3.0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, canvasSize in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                guard elapsed < Self.duration else { return }

                for particle in particles {
                    let time = elapsed - particle.delay
                    guard time > 0 else { continue }

                    let progress = time / (Self.duration - particle.delay)
                    guard progress < 1 else { continue }

                    let x = particle.originX * canvasSize.width + particle.velocityX * time
                    // Launch upward from the top third, gravity pulls back down.
                    let y = canvasSize.height * 0.28
                        - particle.velocityY * time
                        + 480 * time * time
                    guard y < canvasSize.height + 20 else { continue }

                    let sway = sin(time * 6 + Double(particle.originX) * 20) * 12
                    let opacity = progress > 0.7 ? (1 - progress) / 0.3 : 1

                    var particleContext = context
                    particleContext.opacity = opacity
                    particleContext.translateBy(x: x + sway, y: y)
                    particleContext.rotate(by: .radians(time * particle.spinSpeed))

                    let rect = CGRect(
                        x: -particle.size / 2,
                        y: -particle.size / 2,
                        width: particle.size,
                        height: particle.isCircle ? particle.size : particle.size * 0.62
                    )
                    if particle.isCircle {
                        particleContext.fill(Path(ellipseIn: rect), with: .color(particle.color))
                    } else {
                        particleContext.fill(
                            Path(roundedRect: rect, cornerRadius: 1.5),
                            with: .color(particle.color)
                        )
                    }
                }
            }
        }
    }
}
