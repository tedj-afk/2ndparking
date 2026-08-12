import SwiftUI

/// Simple profile screen with role switching and prototype debug toggles.
struct ProfileView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let role: AppRole
    var isTabRoot: Bool = false

    @State private var showEditProfile: Bool = false
    @State private var showPaymentMethods: Bool = false

    private var displayName: String {
        store.displayName(for: role)
    }

    private var memberLine: String {
        switch role {
        case .renter: return "Member since March 2025"
        case .lister: return "Hosting since 2024"
        case .security: return "On duty · LIV Residence"
        }
    }

    private var showsVerifiedSeal: Bool {
        switch role {
        case .renter: return store.isRenterVerified
        case .lister: return true
        case .security: return false
        }
    }

    private var stats: [(value: String, caption: String)] {
        switch role {
        case .renter:
            return [
                ("\(store.reservations.count)", "Bookings"),
                ("4.9", "Rating"),
                ("\(store.vehicles.count)", "Vehicles")
            ]
        case .lister:
            return [
                ("\(store.spots.count)", "Listings"),
                ("4.6", "Rating"),
                ("1.8k", "QAR earned")
            ]
        case .security:
            return [
                ("24", "Check-ins"),
                ("2", "Towers"),
                ("Day", "Shift")
            ]
        }
    }

    var body: some View {
        @Bindable var store = store

        VStack(spacing: 0) {
            if isTabRoot {
                HStack {
                    Text("Profile")
                        .font(.pageTitle)
                        .foregroundStyle(Color.inkPrimary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            } else {
                TopBar(leadingIcon: "arrow.left", onLeading: { dismiss() })
            }

            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    InfoCard(rows: [
                        .init(icon: "phone", label: "Mobile", value: store.profilePhone),
                        .init(icon: "envelope", label: "Email", value: "hello@2ndparking.qa"),
                        .init(icon: "mappin.and.ellipse", label: "City", value: "Doha, Qatar")
                    ])
                    .padding(.horizontal, 16)

                    if role == .renter {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Verification")
                                .padding(.horizontal, 16)
                            HStack(spacing: 10) {
                                Image(systemName: store.isRenterVerified ? "checkmark.seal.fill" : "exclamationmark.circle")
                                    .font(.system(size: 18))
                                    .foregroundStyle(store.isRenterVerified ? Color.successGreen : Color.pendingAmber)
                                Text(store.isRenterVerified ? "ID & residency verified" : "Not verified yet — required before your first booking")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.inkPrimary)
                                Spacer()
                            }
                            .padding(14)
                            .background(store.isRenterVerified ? Color.successPale : Color.orangeFaint)
                            .clipShape(.rect(cornerRadius: 14))
                            .padding(.horizontal, 16)
                        }
                    }

                    if role == .renter {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Payments")
                                .padding(.horizontal, 16)
                            paymentMethodsRow
                                .padding(.horizontal, 16)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Prototype Settings")
                            .padding(.horizontal, 16)
                        VStack(spacing: 10) {
                            ToggleRow(label: "Simulate payment / verification failure", isOn: $store.simulateFailures)
                            if role == .renter {
                                ToggleRow(label: "Renter verified", isOn: $store.isRenterVerified)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    shareCard
                        .padding(.horizontal, 16)

                    SecondaryButton(title: "Switch Role") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            store.activeRole = nil
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                }
                .padding(.bottom, 30)
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(role: role)
        }
        .sheet(isPresented: $showPaymentMethods) {
            PaymentMethodsView()
        }
    }

    /// Entry point into the stored-cards wallet screen.
    private var paymentMethodsRow: some View {
        Button {
            showPaymentMethods = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.brandOrange)
                    .frame(width: 38, height: 38)
                    .background(Color.orangePale)
                    .clipShape(.circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Payment Methods")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.inkPrimary)
                    Text("\(store.paymentCards.count) saved card\(store.paymentCards.count == 1 ? "" : "s") · Apple Pay · QPay")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.inkTertiary)
            }
            .padding(14)
            .background(Color.cardGray)
            .clipShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    /// Invite card that opens the native share sheet with a pre-filled invite link.
    private var shareCard: some View {
        ShareLink(
            item: URL(string: "https://2ndparking.qa/invite")!,
            subject: Text("Join me on 2ndParking"),
            message: Text("I'm using 2ndParking to find and rent private parking spots across Doha — hourly or daily. Join me: https://2ndparking.qa/invite")
        ) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.brandOrange)
                    .frame(width: 38, height: 38)
                    .background(Color.orangePale)
                    .clipShape(.circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Share 2ndParking")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.inkPrimary)
                    Text("Invite friends to find parking in Doha")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.inkTertiary)
            }
            .padding(14)
            .background(Color.cardGray)
            .clipShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var heroCard: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                AvatarCircle(
                    name: displayName,
                    size: 92,
                    foreground: store.avatarStyle.foreground,
                    background: store.avatarStyle.background,
                    imageData: store.avatarImages[role]
                )
                .overlay(Circle().strokeBorder(Color.white, lineWidth: 3))
                .shadow(color: store.avatarStyle.foreground.opacity(0.22), radius: 14, y: 7)
                if showsVerifiedSeal {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 27, height: 27)
                        .background(Color.brandOrange)
                        .clipShape(.circle)
                        .overlay(Circle().strokeBorder(Color.white, lineWidth: 2.5))
                        .offset(x: 2, y: 2)
                }
            }

            VStack(spacing: 5) {
                Text(displayName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.inkPrimary)
                Text(memberLine)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.inkSecondary)
                if !store.profileBio.isEmpty {
                    Text(store.profileBio)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 12)
                        .padding(.top, 2)
                }
                StatusPill(
                    text: "\(role.rawValue) account",
                    dotColor: .brandOrange,
                    background: .white
                )
                .padding(.top, 4)
            }

            Divider()
                .overlay(Color.brandOrange.opacity(0.15))
                .padding(.horizontal, 8)

            HStack(spacing: 0) {
                ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                    ProfileStatItem(value: stat.value, caption: stat.caption)
                    if index < stats.count - 1 {
                        Rectangle()
                            .fill(Color.brandOrange.opacity(0.15))
                            .frame(width: 1, height: 30)
                    }
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.orangeFaint, Color.orangePale.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(.rect(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.orangePale, lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Button {
                showEditProfile = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Edit")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(Color.brandOrange)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(.capsule)
                .shadow(color: .black.opacity(0.07), radius: 5, y: 2)
            }
            .padding(12)
        }
    }
}

/// One value + caption column inside the profile hero card.
private struct ProfileStatItem: View {
    let value: String
    let caption: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.inkPrimary)
            Text(caption)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.inkSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
