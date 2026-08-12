import SwiftUI

/// QR access pass shown after payment and from the active reservation banner.
struct AccessPassView: View {
    @Environment(\.dismiss) private var dismiss

    let reservation: Reservation
    var onViewReservation: (() -> Void)? = nil

    private var payload: String {
        "2NDPARKING|\(reservation.id.uuidString)|\(reservation.spot.spotCode)|\(reservation.plateNumber)"
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(leadingIcon: "xmark", onLeading: { dismiss() })

            ScrollView {
                VStack(spacing: 0) {
                    Text(reservation.title)
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)

                    HStack(spacing: 8) {
                        IconMetaRow(icon: "calendar", text: reservation.dateLabel)
                        if let start = reservation.startTime, let end = reservation.endTime {
                            IconMetaRow(icon: "clock", text: start, secondText: end)
                        } else if let endDate = reservation.endDateLabel {
                            IconMetaRow(icon: "arrow.right", text: endDate)
                        }
                    }
                    .padding(.top, 10)

                    QRCodeView(payload: payload)
                        .frame(width: 250, height: 250)
                        .padding(.top, 36)

                    Text("\(reservation.vehicleBrand) \(reservation.vehicleModel) | \(reservation.plateNumber)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkPrimary)
                        .padding(.top, 26)

                    Text("Scan the QR code above to check-in with security before accessing the building")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 44)
                        .padding(.top, 10)
                }
            }

            VStack(spacing: 14) {
                ShareLink(item: "2ndParking Access Pass — \(reservation.title), \(reservation.dateLabel). Vehicle \(reservation.plateNumber).") {
                    Text("Share Access Pass")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.brandOrange)
                        .clipShape(.rect(cornerRadius: 16))
                }
                if let onViewReservation {
                    TextLinkButton(title: "View Reservation", action: onViewReservation)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(Color.white)
    }
}
