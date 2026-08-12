import SwiftUI

/// Shared notifications list with unread count badge. Lister "New Request" opens the request screen.
struct NotificationsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let role: AppRole
    var isTabRoot: Bool = false
    var onOpenRequest: (() -> Void)? = nil
    /// Called with a reservation ID when a linked notification is tapped.
    var onOpenReservation: ((UUID) -> Void)? = nil

    var body: some View {
        let notifications = store.notifications(for: role)
        let unread = store.unreadCount(for: role)

        VStack(spacing: 0) {
            if isTabRoot {
                Spacer().frame(height: 18)
            } else {
                TopBar(leadingIcon: "arrow.left", onLeading: { dismiss() })
            }

            HStack(spacing: 10) {
                Text("Notifications")
                    .font(.pageTitle)
                    .foregroundStyle(Color.inkPrimary)
                if unread > 0 {
                    Text("\(unread)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.failureRed)
                        .clipShape(.circle)
                }
                Spacer()
                if unread > 0 {
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            store.markNotificationsRead(for: role)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Mark all as read")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color.brandOrange)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(notifications) { notification in
                        if notification.opensRequest, let onOpenRequest {
                            Button(action: onOpenRequest) {
                                NotificationRow(notification: notification, showsChevron: true)
                            }
                        } else if let reservationID = notification.reservationID,
                                  let onOpenReservation,
                                  store.reservation(id: reservationID) != nil {
                            Button {
                                onOpenReservation(reservationID)
                            } label: {
                                NotificationRow(notification: notification, showsChevron: true)
                            }
                        } else {
                            NotificationRow(notification: notification)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .refreshable {
                await store.refreshNotifications(for: role)
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear { store.markNotificationsRead(for: role) }
    }
}
