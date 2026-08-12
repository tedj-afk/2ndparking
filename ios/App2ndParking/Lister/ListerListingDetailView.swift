import SwiftUI

/// Lister-facing spot detail with Live status pill, View Reservations + Edit Listing.
struct ListerListingDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let spotID: UUID
    @Binding var path: [ListerRoute]

    @State private var showArchiveDialog: Bool = false
    @State private var showAvailabilityEditor: Bool = false

    var body: some View {
        Group {
            if let spot = store.spot(id: spotID) {
                content(spot: spot)
            } else {
                Color.white.onAppear { dismiss() }
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func content(spot: ParkingSpot) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ImageCarousel(photos: spot.photos, onBack: { dismiss() }, onMore: { showArchiveDialog = true })

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top) {
                            Text(spot.spotCode)
                                .font(.system(size: 27, weight: .bold))
                                .foregroundStyle(Color.inkPrimary)
                            Spacer()
                            StatusPill(
                                text: spot.status == .reserved ? "Reserved" : spot.status == .archived ? "Archived" : "Live",
                                dotColor: spot.status.dotColor,
                                background: spot.status.pillBackground
                            )
                        }
                        Text(spot.buildingName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.inkPrimary)
                            .padding(.top, -6)

                        HStack(alignment: .top, spacing: 8) {
                            Text(spot.address)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.inkSecondary)
                            Spacer()
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 17))
                                .foregroundStyle(Color.brandOrange)
                                .frame(width: 42, height: 42)
                                .background(Color.orangePale)
                                .clipShape(.circle)
                        }
                    }
                    .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Description")
                        Text(spot.description)
                            .font(.system(size: 15))
                            .foregroundStyle(Color.inkSecondary)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Pricing")
                        InfoCard(rows: pricingRows(spot: spot))
                    }
                    .padding(.horizontal, 16)

                    availabilityBlock(spot: spot)
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Parking Details")
                        ParkingDetailsCard(spot: spot)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 24)
            }
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 12) {
                Divider().overlay(Color.borderGray.opacity(0.5))
                PrimaryButton(title: "View Reservations") {
                    path.append(.listingReservations(spot.id))
                }
                .padding(.horizontal, 16)
                TextLinkButton(title: "Edit Listing") {}
            }
            .padding(.bottom, 10)
            .background(Color.white)
        }
        .sheet(isPresented: $showAvailabilityEditor) {
            AvailabilityEditorView(spotID: spotID)
                .presentationDragIndicator(.visible)
        }
        .dialogOverlay(isPresented: showArchiveDialog) {
            ConfirmationDialogView(
                icon: .warning,
                title: "Archive listing?",
                message: "Archived listings are hidden from renters. You can restore them anytime.",
                primaryTitle: "Archive",
                primaryAction: {
                    showArchiveDialog = false
                    if let index = store.spots.firstIndex(where: { $0.id == spotID }) {
                        store.spots[index].status = .archived
                    }
                    dismiss()
                },
                secondaryTitle: "Keep",
                secondaryAction: { showArchiveDialog = false }
            )
        }
    }

    /// Availability summary with a shortcut into the weekly-hours editor.
    private func availabilityBlock(spot: ParkingSpot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(title: "Availability")
                Button("Edit") {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    showAvailabilityEditor = true
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.brandOrange)
                .fixedSize()
            }

            if spot.schedule.isPaused {
                HStack(spacing: 9) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.pendingAmber)
                    Text("Bookings paused — renters can't request this spot.")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Color.inkPrimary)
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(Color.pendingAmber.opacity(0.13))
                .clipShape(.rect(cornerRadius: 13))
            }

            AvailabilityWeekCard(schedule: spot.schedule)

            Button {
                showAvailabilityEditor = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.minus")
                        .font(.system(size: 13, weight: .bold))
                    Text("Block a date I need the spot")
                        .font(.system(size: 14, weight: .bold))
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(Color.brandOrange)
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(Color.orangeFaint)
                .clipShape(.rect(cornerRadius: 13))
            }
            .buttonStyle(.plain)
        }
    }

    private func pricingRows(spot: ParkingSpot) -> [InfoCard.DetailRowData] {
        var rows: [InfoCard.DetailRowData] = []
        if let hourly = spot.pricePerHour {
            rows.append(.init(icon: "clock", label: "Hourly", value: "\(Int(hourly)) QAR/h"))
        }
        if let daily = spot.pricePerDay {
            rows.append(.init(icon: "sun.max", label: "Daily", value: "\(Int(daily)) QAR/day"))
        }
        if rows.isEmpty {
            rows.append(.init(icon: "banknote", label: "Pricing", value: "Not set"))
        }
        return rows
    }
}
