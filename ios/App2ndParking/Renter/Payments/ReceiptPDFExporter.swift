import SwiftUI

/// Renders a payment receipt into a shareable, print-ready PDF document.
enum ReceiptPDFExporter {
    private static let pageSize = CGSize(width: 612, height: 792) // US Letter, points

    /// Generates the PDF in the temporary directory and returns its file URL.
    static func generate(record: PaymentRecord, reservation: Reservation?) -> URL? {
        let page = ReceiptPDFPage(record: record, reservation: reservation)
        let renderer = ImageRenderer(content: page)
        renderer.proposedSize = ProposedViewSize(pageSize)

        let safeReference = record.reference.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("2ndParking Receipt \(safeReference).pdf")

        var didWrite = false
        renderer.render { size, renderContent in
            var mediaBox = CGRect(origin: .zero, size: pageSize)
            guard let consumer = CGDataConsumer(url: url as CFURL),
                  let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
                return
            }
            pdfContext.beginPDFPage(nil)
            pdfContext.translateBy(
                x: (pageSize.width - size.width) / 2,
                y: (pageSize.height - size.height) / 2
            )
            renderContent(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
            didWrite = true
        }
        return didWrite ? url : nil
    }
}

/// The printable receipt page laid out at US Letter size.
private struct ReceiptPDFPage: View {
    let record: PaymentRecord
    let reservation: Reservation?

    private var scheduleLabel: String? {
        guard let reservation else { return nil }
        if let start = reservation.startTime, let end = reservation.endTime {
            return "\(reservation.dateLabel) · \(start) – \(end)"
        }
        if let endDate = reservation.endDateLabel {
            return "\(reservation.dateLabel) → \(endDate)"
        }
        return reservation.dateLabel
    }

    private var detailRows: [(String, String)] {
        var rows: [(String, String)] = [("Paid with", record.methodTitle)]
        if let reservation {
            rows.append(("Spot", "\(reservation.spot.spotCode) · \(reservation.spot.buildingName)"))
            rows.append(("Address", reservation.spot.address))
            if let scheduleLabel {
                rows.append(("Schedule", scheduleLabel))
            }
            rows.append(("Duration", reservation.bookedDurationLabel))
            rows.append(("Vehicle", "\(reservation.vehicleBrand) \(reservation.vehicleModel) · \(reservation.plateNumber)"))
            rows.append(("Guest", reservation.guestName))
        }
        rows.append(("Reference", record.reference))
        return rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 28)

            amountBlock
                .padding(.bottom, 32)

            detailsCard

            Spacer()

            footer
        }
        .padding(56)
        .frame(width: 612, height: 792)
        .background(Color.white)
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .top) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color.brandOrange)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "parkingsign")
                            .font(.system(size: 21, weight: .bold))
                            .foregroundStyle(.white)
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text("2ndParking")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(Color.inkPrimary)
                    Text("Doha, Qatar")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.inkSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("PAYMENT RECEIPT")
                    .font(.system(size: 13, weight: .heavy))
                    .kerning(1.2)
                    .foregroundStyle(Color.brandOrange)
                Text(record.paidAtLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkSecondary)
            }
        }
    }

    private var amountBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AMOUNT PAID")
                .font(.system(size: 11, weight: .semibold))
                .kerning(1)
                .foregroundStyle(Color.inkSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(Int(record.amount))")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(Color.inkPrimary)
                Text("QAR")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.inkSecondary)
            }

            HStack(spacing: 12) {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                    Text("Paid · \(record.paidAtLabel)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.successGreen)

                if let reservation {
                    HStack(spacing: 5) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text("\(reservation.bookedDurationLabel) of parking")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(Color.brandOrange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.orangePale)
                    .clipShape(.capsule)
                }
            }
        }
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(detailRows.enumerated()), id: \.offset) { index, row in
                HStack(alignment: .top) {
                    Text(row.0)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkSecondary)
                        .frame(width: 130, alignment: .leading)
                    Text(row.1)
                        .font(.system(
                            size: 13,
                            weight: .semibold,
                            design: row.0 == "Reference" ? .monospaced : .default
                        ))
                        .foregroundStyle(Color.inkPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 13)

                if index < detailRows.count - 1 {
                    Divider()
                        .overlay(Color.borderGray.opacity(0.5))
                        .padding(.horizontal, 20)
                }
            }
        }
        .background(Color.cardGray)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.borderGray.opacity(0.6), lineWidth: 1)
        )
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle()
                .fill(Color.borderGray.opacity(0.6))
                .frame(height: 1)
            HStack {
                Text("Thank you for parking with 2ndParking.")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.inkPrimary)
                Spacer()
                Text("support@2ndparking.qa · +974 4444 0000")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkSecondary)
            }
        }
    }
}
