import SwiftUI

/// Scrollable mock contract + draw-to-sign canvas.
struct ContractSigningView: View {
    let reservation: Reservation
    let onSigned: () -> Void
    let onClose: () -> Void

    @State private var strokes: [[CGPoint]] = []
    @State private var currentStroke: [CGPoint] = []

    private var hasSignature: Bool {
        !strokes.isEmpty || currentStroke.count > 2
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(leadingIcon: "xmark", onLeading: onClose)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Rental Contract")
                        .font(.pageTitle)
                        .foregroundStyle(Color.inkPrimary)

                    VStack(alignment: .leading, spacing: 12) {
                        contractParagraph(
                            title: "1. Parties",
                            body: "This parking rental agreement is made between \(reservation.spot.listerName) (the \"Lister\") and \(reservation.guestName) (the \"Renter\") through the 2ndParking platform."
                        )
                        contractParagraph(
                            title: "2. Parking Spot",
                            body: "Spot \(reservation.spot.spotCode), \(reservation.spot.level), \(reservation.spot.buildingName). Access type: \(reservation.spot.accessType)."
                        )
                        contractParagraph(
                            title: "3. Term & Rent",
                            body: "Monthly rental from \(reservation.dateLabel) to \(reservation.endDateLabel ?? "—") at \(String(format: "%.0f", reservation.totalPrice)) QAR per month, payable in advance."
                        )
                        contractParagraph(
                            title: "4. Vehicle",
                            body: "Registered vehicle: \(reservation.vehicleBrand) \(reservation.vehicleModel), plate \(reservation.plateNumber). Only the registered vehicle may use the spot."
                        )
                        contractParagraph(
                            title: "5. Termination",
                            body: "Either party may terminate with 14 days written notice through the platform. The deposit is refunded within 5 business days after the spot is vacated."
                        )
                    }
                    .padding(16)
                    .background(Color.cardGray)
                    .clipShape(.rect(cornerRadius: 16))

                    SectionHeader(title: "Sign below")

                    signatureCanvas
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }

            PrimaryButton(title: "Confirm & Sign", isEnabled: hasSignature) {
                onSigned()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color.white)
    }

    private func contractParagraph(title: String, body text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkPrimary)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color.inkSecondary)
                .lineSpacing(2)
        }
    }

    private var signatureCanvas: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.borderGray, style: StrokeStyle(lineWidth: 1.4, dash: [6, 5]))

            if !hasSignature {
                Text("Draw your signature here")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.inkTertiary)
            }

            Canvas { context, _ in
                var allStrokes = strokes
                if !currentStroke.isEmpty {
                    allStrokes.append(currentStroke)
                }
                for stroke in allStrokes where stroke.count > 1 {
                    var path = Path()
                    path.move(to: stroke[0])
                    for point in stroke.dropFirst() {
                        path.addLine(to: point)
                    }
                    context.stroke(path, with: .color(.inkPrimary), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                }
            }
            .clipShape(.rect(cornerRadius: 14))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        currentStroke.append(value.location)
                    }
                    .onEnded { _ in
                        if currentStroke.count > 1 {
                            strokes.append(currentStroke)
                        }
                        currentStroke = []
                    }
            )
        }
        .frame(height: 160)
        .overlay(alignment: .topTrailing) {
            if hasSignature {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        strokes = []
                        currentStroke = []
                    }
                } label: {
                    Text("Clear")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.brandOrange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
            }
        }
    }
}
