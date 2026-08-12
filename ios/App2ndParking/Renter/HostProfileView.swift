import SwiftUI

/// Mock review shown on the host profile sheet.
private struct HostReview: Identifiable {
    let id = UUID()
    let author: String
    let timeAgo: String
    let rating: Int
    let text: String

    static let samples: [HostReview] = [
        HostReview(author: "Sara M.", timeAgo: "2 weeks ago", rating: 5, text: "Super easy check-in, the spot was exactly as described and right next to the elevator. Would book again!"),
        HostReview(author: "Omar K.", timeAgo: "1 month ago", rating: 5, text: "Great host — quick to respond and the security team knew I was coming. Very smooth experience."),
        HostReview(author: "Fatima A.", timeAgo: "2 months ago", rating: 4, text: "Good covered spot in a clean garage. The ramp is a little tight for big SUVs but everything else was perfect.")
    ]
}

/// Full sheet with the lister's info, reviews and their listed spots.
struct HostProfileView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let hostName: String
    let verified: Bool

    private var hostSpots: [ParkingSpot] {
        store.spots.filter { $0.listerName == hostName && $0.status != .archived }
    }

    private var averageRating: Double {
        let rated = hostSpots.filter { $0.rating > 0 }
        guard !rated.isEmpty else { return 4.8 }
        return rated.map(\.rating).reduce(0, +) / Double(rated.count)
    }

    private var totalReviews: Int {
        hostSpots.map(\.reviewCount).reduce(0, +)
    }

    private var firstName: String {
        hostName.split(separator: " ").first.map(String.init) ?? hostName
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                CircleIconButton(systemName: "xmark") { dismiss() }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    identityCard

                    aboutBlock

                    divider

                    reviewsBlock

                    divider

                    spotsBlock
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 32)
            }
        }
        .background(Color.white)
    }

    private var divider: some View {
        Divider().overlay(Color.borderGray.opacity(0.6))
    }

    private var identityCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 10) {
                AvatarCircle(name: hostName, size: 92)
                HStack(spacing: 6) {
                    Text(hostName)
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(Color.inkPrimary)
                    if verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 17))
                            .foregroundStyle(Color.brandOrange)
                    }
                }
                Text(verified ? "Verified resident host" : "Resident host")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.inkSecondary)
            }

            HStack(spacing: 0) {
                statColumn(value: String(format: "%.1f", averageRating), label: "Rating", icon: "star.fill")
                statDivider
                statColumn(value: "\(totalReviews)", label: "Reviews", icon: nil)
                statDivider
                statColumn(value: "\(max(hostSpots.count, 1))", label: hostSpots.count == 1 ? "Spot" : "Spots", icon: nil)
            }
            .padding(.vertical, 14)
            .background(Color.cardGray)
            .clipShape(.rect(cornerRadius: 16))
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.borderGray.opacity(0.7))
            .frame(width: 1, height: 34)
    }

    private func statColumn(value: String, label: String, icon: String?) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.starGold)
                }
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.inkPrimary)
            }
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color.inkSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var aboutBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "About \(firstName)")
            Text("Lives in the building and rents out spare parking when it's not in use. Responds quickly and coordinates with building security so your arrival is smooth.")
                .font(.system(size: 15))
                .foregroundStyle(Color.inkSecondary)
                .lineSpacing(3)

            HStack(spacing: 14) {
                Label("Responds within 1 hour", systemImage: "bubble.left")
                Label("Hosting since 2025", systemImage: "clock.arrow.circlepath")
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color.inkSecondary)
            .padding(.top, 4)
        }
    }

    private var reviewsBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "What renters say")
            ForEach(HostReview.samples) { review in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        AvatarCircle(name: review.author, size: 36)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(review.author)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.inkPrimary)
                            Text(review.timeAgo)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.inkTertiary)
                        }
                        Spacer()
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { star in
                                Image(systemName: star < review.rating ? "star.fill" : "star")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.starGold)
                            }
                        }
                    }
                    Text(review.text)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.inkSecondary)
                        .lineSpacing(2)
                }
                .padding(14)
                .background(Color.cardGray)
                .clipShape(.rect(cornerRadius: 16))
            }
        }
    }

    private var spotsBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "\(firstName)'s spots")
            if hostSpots.isEmpty {
                Text("No active listings right now.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.inkSecondary)
            }
            ForEach(hostSpots) { spot in
                HStack(spacing: 12) {
                    SpotPhoto(name: spot.photos.first ?? "")
                        .frame(width: 74, height: 74)
                        .clipShape(.rect(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(spot.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.inkPrimary)
                            .lineLimit(1)
                        Text("\(spot.areaName), Doha")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.inkSecondary)
                        HStack(spacing: 8) {
                            if let hourly = spot.pricePerHour {
                                Text("\(Int(hourly)) QAR/h")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.brandOrange)
                            } else if let daily = spot.pricePerDay {
                                Text("\(Int(daily)) QAR/day")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.brandOrange)
                            }
                            if spot.hasChargingStation {
                                HStack(spacing: 2) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 10))
                                    Text("EV")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundStyle(Color.successGreen)
                            }
                        }
                    }
                    Spacer()
                    RatingLabel(rating: spot.rating, count: spot.reviewCount)
                }
                .padding(12)
                .background(Color.cardGray)
                .clipShape(.rect(cornerRadius: 16))
            }
        }
    }
}
