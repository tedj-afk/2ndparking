import SwiftUI

/// Renter-facing spot detail: carousel, Airbnb-style info hierarchy, sticky Reserve bar.
/// Access instructions are intentionally hidden here — they appear on the reservation after booking.
struct SpotDetailsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let spotID: UUID
    let query: SearchQuery
    @Binding var path: [RenterRoute]

    @State private var showVerification: Bool = false
    @State private var showBooking: Bool = false
    @State private var showHostProfile: Bool = false
    @State private var isSaved: Bool = false

    /// Whether the owner's rules allow the dates/times the renter searched for.
    private func availability(for spot: ParkingSpot) -> AvailabilitySchedule.Check {
        spot.availability(for: query)
    }

    var body: some View {
        if let spot = store.spot(id: spotID) {
            content(spot: spot)
        } else {
            Color.white.onAppear { dismiss() }
        }
    }

    private func content(spot: ParkingSpot) -> some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        ImageCarousel(photos: spot.photos)

                        titleBlock(spot: spot)
                            .padding(.horizontal, 16)

                        sectionDivider

                        hostBlock(spot: spot)
                            .padding(.horizontal, 16)

                        sectionDivider

                        highlightsBlock(spot: spot)
                            .padding(.horizontal, 16)

                        sectionDivider

                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "About this spot")
                            Text(spot.description)
                                .font(.system(size: 15))
                                .foregroundStyle(Color.inkSecondary)
                                .lineSpacing(3)
                        }
                        .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Availability")
                            AvailabilityWeekCard(schedule: spot.schedule, highlightedDay: Weekday.from(query.startDate))
                            AvailabilityNoticeBanner(check: availability(for: spot)) { dismiss() }
                        }
                        .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Parking Details")
                            ParkingDetailsCard(spot: spot)
                        }
                        .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Where you'll park")
                            MapSnapshotView(latitude: spot.latitude, longitude: spot.longitude)
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.brandOrange)
                                Text(spot.address)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.inkSecondary)
                            }
                        }
                        .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Cancellation Policy")
                            Text(spot.cancellationPolicy)
                                .font(.system(size: 15))
                                .foregroundStyle(Color.inkSecondary)
                                .lineSpacing(3)
                        }
                        .padding(.horizontal, 16)

                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.inkSecondary)
                            Text("Access instructions are shared once your booking is confirmed.")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.inkSecondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.fieldGray)
                        .clipShape(.rect(cornerRadius: 12))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
                .ignoresSafeArea(edges: .top)

                stickyBar(spot: spot)
            }

            floatingButtons
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showVerification) {
            VerificationWizardView {
                store.isRenterVerified = true
                showVerification = false
                Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    showBooking = true
                }
            } onClose: {
                showVerification = false
            }
        }
        .fullScreenCover(isPresented: $showBooking) {
            BookingFlowView(spot: spot, query: query, path: $path)
        }
        .sheet(isPresented: $showHostProfile) {
            HostProfileView(hostName: spot.listerName, verified: spot.listerVerified)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Floating glass controls

    private var floatingButtons: some View {
        HStack {
            GlassCircleButton(systemName: "chevron.left") { dismiss() }
            Spacer()
            HStack(spacing: 10) {
                GlassCircleButton(systemName: isSaved ? "heart.fill" : "heart", tint: isSaved ? .brandOrange : .inkPrimary) {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isSaved.toggle()
                    }
                }
                Menu {
                    ShareLink(item: "Check out this parking spot on 2ndParking: \(store.spot(id: spotID)?.title ?? "")") {
                        Label("Share spot", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        showHostProfile = true
                    } label: {
                        Label("View host profile", systemImage: "person.crop.circle")
                    }
                    Button(role: .destructive) {} label: {
                        Label("Report listing", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.inkPrimary)
                        .frame(width: 40, height: 40)
                        .contentShape(.circle)
                }
                .liquidGlass(in: .circle, interactive: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Blocks

    private func titleBlock(spot: ParkingSpot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(spot.title)
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(Color.inkPrimary)

            HStack(spacing: 5) {
                Image(systemName: "star.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkPrimary)
                Text(String(format: "%.1f", spot.rating))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.inkPrimary)
                Text("· \(spot.reviewCount) reviews · \(spot.areaName), Doha")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.inkSecondary)
            }

            HStack(spacing: 8) {
                if spot.hasChargingStation {
                    TagChip(icon: "bolt.fill", text: "EV Charging", tint: .successGreen)
                }
                TagChip(icon: "parkingsign.square", text: spot.level)
                TagChip(icon: "video", text: spot.securityType)
            }
            .padding(.top, 2)
        }
    }

    private func hostBlock(spot: ParkingSpot) -> some View {
        Button {
            showHostProfile = true
        } label: {
            HStack(spacing: 12) {
                AvatarCircle(name: spot.listerName, size: 48)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Hosted by \(spot.listerName)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.inkPrimary)
                        if spot.listerVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.brandOrange)
                        }
                    }
                    Text(spot.listerVerified ? "Verified resident host" : "Resident host")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.inkTertiary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func highlightsBlock(spot: ParkingSpot) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            highlightRow(icon: "key", title: spot.accessType, subtitle: "Smooth arrival — the building team is expecting you.")
            highlightRow(
                icon: "clock",
                title: spot.schedule.openDaysSummary,
                subtitle: spot.schedule.compactSummary
            )
            if spot.hasChargingStation {
                highlightRow(icon: "bolt.car", title: "EV charging on the spot", subtitle: "Charge while you're parked, no extra hassle.")
            }
            highlightRow(icon: "checkmark.shield", title: spot.securityType, subtitle: "The garage is monitored around the clock.")
        }
    }

    private func highlightRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 19))
                .foregroundStyle(Color.inkPrimary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.inkPrimary)
                Text(subtitle)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color.inkSecondary)
            }
        }
    }

    private var sectionDivider: some View {
        Divider()
            .overlay(Color.borderGray.opacity(0.6))
            .padding(.horizontal, 16)
    }

    // MARK: - Sticky bar

    private func stickyBar(spot: ParkingSpot) -> some View {
        let check = availability(for: spot)
        return HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                PriceText(amount: query.totalPrice(for: spot), size: 24)
                Text(query.durationNote)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.inkSecondary)
                if check.isAvailable {
                    Text(query.scheduleSummary)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.inkSecondary)
                        .underline()
                } else {
                    Text(check.title ?? "Unavailable")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.pendingAmber)
                }
            }
            Spacer()
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                guard check.isAvailable else {
                    dismiss()
                    return
                }
                if store.isRenterVerified {
                    showBooking = true
                } else {
                    showVerification = true
                }
            } label: {
                Text(check.isAvailable ? "Reserve" : "Change Times")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 150, height: 54)
                    .background(check.isAvailable ? Color.brandOrange : Color.inkPrimary)
                    .clipShape(.rect(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.06), radius: 10, y: -4)
                .ignoresSafeArea()
        )
    }
}

/// InfoCard preset for the standard "Parking Details" block.
struct ParkingDetailsCard: View {
    let spot: ParkingSpot

    var body: some View {
        InfoCard(rows: [
            .init(icon: "parkingsign.square", label: "Spot Label", value: spot.spotCode),
            .init(icon: "arrow.down.right.circle", label: "Level", value: spot.level),
            .init(icon: "key", label: "Access Type", value: spot.accessType),
            .init(icon: "arrow.up.left.and.arrow.down.right", label: "Car Size Limit", value: spot.maxVehicleHeight),
            .init(icon: "clock", label: "Available Times", value: spot.availableTimes),
            .init(icon: "bolt.car", label: "Charging Station", value: spot.hasChargingStation ? "Available" : "No"),
            .init(icon: "video", label: "Security", value: spot.securityType)
        ])
    }
}

/// Numbered orange-chip instruction list (shown on confirmed reservations only).
struct AccessInstructionsList: View {
    let instructions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(instructions.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.brandOrange)
                        .frame(width: 26, height: 26)
                        .background(Color.orangePale)
                        .clipShape(.circle)
                    Text(step)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.inkPrimary)
                        .lineSpacing(2)
                }
            }
        }
    }
}
