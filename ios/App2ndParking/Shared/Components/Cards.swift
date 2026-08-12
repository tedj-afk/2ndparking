import SwiftUI

/// Small rounded pill with colored status dot + label.
struct StatusPill: View {
    let text: String
    let dotColor: Color
    var background: Color = .fieldGray

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 7, height: 7)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.inkPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(background)
        .clipShape(.capsule)
    }
}

/// Horizontal pill filter row. Selected = solid dark, unselected = light gray.
struct FilterTabs: View {
    let options: [String]
    @Binding var selection: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selection = option
                        }
                    } label: {
                        Text(option)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(selection == option ? Color.white : Color.inkPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(selection == option ? Color.inkPrimary : Color.fieldGray)
                            .clipShape(.capsule)
                    }
                }
            }
        }
        .contentMargins(.horizontal, 16)
    }
}

/// One `[icon] Label ..... Value` row inside an InfoCard.
struct DetailRow: View {
    var icon: String? = nil
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.brandOrange)
                    .frame(width: 22)
            }
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.inkPrimary)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(size: 15))
                .foregroundStyle(Color.inkPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 11)
    }
}

/// Light-gray rounded card that stacks DetailRows with thin separators.
struct InfoCard: View {
    let rows: [DetailRowData]

    struct DetailRowData: Identifiable {
        let id = UUID()
        var icon: String? = nil
        let label: String
        let value: String
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                DetailRow(icon: row.icon, label: row.label, value: row.value)
                if index < rows.count - 1 {
                    Divider().overlay(Color.borderGray.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(Color.cardGray)
        .clipShape(.rect(cornerRadius: 16))
    }
}

/// Section header ("Parking Details", "Access Instructions").
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.sectionHeader)
            .foregroundStyle(Color.inkPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Liquid-glass capsule showing distance to the spot, overlaid on listing photos.
struct DistanceBadge: View {
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "location.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.brandOrange)
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.inkPrimary)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .liquidGlass(in: .capsule)
    }
}

/// Liquid-glass capsule marking spots with an EV charging station.
struct EVBadge: View {
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.successGreen)
            Text(compact ? "EV" : "EV Charging")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.inkPrimary)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .liquidGlass(in: .capsule)
    }
}

/// Inline tag chip used in detail screens (e.g. "EV Charging", "Covered").
struct TagChip: View {
    let icon: String
    let text: String
    var tint: Color = .brandOrange

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.inkPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.fieldGray)
        .clipShape(.capsule)
    }
}

/// Star + score + review count.
struct RatingLabel: View {
    let rating: Double
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 13))
                .foregroundStyle(Color.starGold)
            Text(String(format: "%.1f", rating))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.inkPrimary)
            Text("(\(count))")
                .font(.system(size: 14))
                .foregroundStyle(Color.inkSecondary)
        }
    }
}

/// Calendar / clock metadata row used in cards and details.
struct IconMetaRow: View {
    let icon: String
    let text: String
    var secondIcon: String? = nil
    var secondText: String? = nil
    var textColor: Color = .inkPrimary

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.brandOrange)
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(textColor)
            if let secondText {
                Image(systemName: secondIcon ?? "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.brandOrange)
                Text(secondText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(textColor)
            }
        }
    }
}

/// Reusable listing/reservation card: thumbnail + title + meta rows.
struct ListingCard: View {
    let photo: String
    let title: String
    var rows: [MetaLine]
    var trailingText: String? = nil
    var rating: (Double, Int)? = nil
    /// Text-only variant (security gate log): drops the thumbnail.
    var showsPhoto: Bool = true

    struct MetaLine: Identifiable {
        let id = UUID()
        var icon: String? = nil
        var text: String
        var secondText: String? = nil
        var textColor: Color = .inkPrimary
        var isBoldOrange: Bool = false
        /// Tints icon + text and bolds the row (used for security states and delays).
        var tint: Color? = nil
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if showsPhoto {
                SpotPhoto(name: photo)
                    .frame(width: 92, height: 92)
                    .clipShape(.rect(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .top) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.inkPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 4)
                    if let trailingText {
                        Text(trailingText)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.inkSecondary)
                    }
                }
                ForEach(rows) { row in
                    HStack(spacing: 7) {
                        if let icon = row.icon {
                            Image(systemName: icon)
                                .font(.system(size: 13, weight: row.tint == nil ? .medium : .bold))
                                .foregroundStyle(row.tint ?? Color.brandOrange)
                        }
                        Text(row.text)
                            .font(.system(size: 14, weight: (row.isBoldOrange || row.tint != nil) ? .bold : .medium))
                            .foregroundStyle(row.tint ?? (row.isBoldOrange ? Color.brandOrange : row.textColor))
                        if let second = row.secondText {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.brandOrange)
                            Text(second)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(row.textColor)
                        }
                    }
                }
                if let rating {
                    RatingLabel(rating: rating.0, count: rating.1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Color.cardGray)
        .clipShape(.rect(cornerRadius: 18))
    }
}

/// Notification row with a category icon in a tinted circle, unread dot and timestamp.
/// Unread rows get a bold title, tinted background and orange border.
struct NotificationRow: View {
    let notification: AppNotification
    var showsChevron: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(notification.tint.color)
                    .frame(width: 44, height: 44)
                Image(systemName: notification.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(notification.tint.iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(notification.title)
                    .font(.system(size: 15, weight: notification.isUnread ? .bold : .semibold))
                    .foregroundStyle(Color.inkPrimary)
                Text(notification.message)
                    .font(.system(size: 14, weight: notification.isUnread ? .medium : .regular))
                    .foregroundStyle(notification.isUnread ? Color.inkPrimary.opacity(0.75) : Color.inkSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 8) {
                if notification.isUnread {
                    Circle()
                        .fill(Color.brandOrange)
                        .frame(width: 9, height: 9)
                } else if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.inkTertiary)
                }
                Spacer(minLength: 0)
                Text(notification.timeAgo)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.inkTertiary)
            }
        }
        .padding(14)
        .frame(minHeight: 84)
        .background(notification.isUnread ? Color.orangeFaint : Color.cardGray)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(notification.isUnread ? Color.brandOrange.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
    }
}
