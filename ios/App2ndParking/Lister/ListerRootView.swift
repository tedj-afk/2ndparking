import SwiftUI

enum ListerRoute: Hashable {
    case listingDetail(UUID)
    case listingReservations(UUID)
    case reservationDetail(UUID)
    case incomingRequest
    case payouts
    case notifications
    case profile
}

enum ListerTab: Hashable {
    case listings
    case payouts
    case notifications
    case profile
}

/// Lister experience: bottom tab bar with per-tab navigation stacks.
struct ListerRootView: View {
    @Environment(AppStore.self) private var store

    @State private var selectedTab: ListerTab = .listings
    @State private var listingsPath: [ListerRoute] = []
    @State private var notificationsPath: [ListerRoute] = []
    @State private var showAddListing: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Listings", systemImage: "parkingsign.square", value: ListerTab.listings) {
                NavigationStack(path: $listingsPath) {
                    MyListingsView(path: $listingsPath, showAddListing: $showAddListing)
                        .navigationDestination(for: ListerRoute.self) { route in
                            destination(for: route, path: $listingsPath)
                        }
                }
            }

            Tab("Payouts", systemImage: "creditcard", value: ListerTab.payouts) {
                NavigationStack {
                    PayoutsView(isTabRoot: true)
                }
            }

            Tab("Notifications", systemImage: "bell", value: ListerTab.notifications) {
                NavigationStack(path: $notificationsPath) {
                    NotificationsView(
                        role: .lister,
                        isTabRoot: true,
                        onOpenRequest: { notificationsPath.append(.incomingRequest) },
                        onOpenReservation: { notificationsPath.append(.reservationDetail($0)) }
                    )
                    .navigationDestination(for: ListerRoute.self) { route in
                        destination(for: route, path: $notificationsPath)
                    }
                }
            }
            .badge(store.unreadCount(for: .lister))

            Tab("Profile", systemImage: "person.crop.circle", value: ListerTab.profile) {
                NavigationStack {
                    ProfileView(role: .lister, isTabRoot: true)
                }
            }
        }
        .tint(Color.brandOrange)
        .minimizingTabBar()
        .fullScreenCover(isPresented: $showAddListing) {
            AddListingWizardView()
        }
    }

    @ViewBuilder
    private func destination(for route: ListerRoute, path: Binding<[ListerRoute]>) -> some View {
        switch route {
        case .listingDetail(let id):
            ListerListingDetailView(spotID: id, path: path)
        case .listingReservations(let id):
            ListerReservationsView(spotID: id, path: path)
        case .reservationDetail(let id):
            ReservationDetailView(reservationID: id, role: .lister)
        case .incomingRequest:
            IncomingRequestView(path: path)
        case .payouts:
            PayoutsView()
        case .notifications:
            NotificationsView(
                role: .lister,
                onOpenRequest: { path.wrappedValue.append(.incomingRequest) },
                onOpenReservation: { path.wrappedValue.append(.reservationDetail($0)) }
            )
        case .profile:
            ProfileView(role: .lister)
        }
    }
}
