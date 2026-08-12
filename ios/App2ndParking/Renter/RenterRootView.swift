import SwiftUI

enum RenterRoute: Hashable {
    case searchResults(SearchQuery)
    case spotDetails(UUID, SearchQuery)
    case myReservations
    case reservationDetails(UUID)
    case requestDetails(UUID)
    case notifications
    case profile
}

enum RenterTab: Hashable {
    case explore
    case reservations
    case notifications
    case profile
}

/// Renter experience: bottom tab bar with per-tab navigation stacks.
struct RenterRootView: View {
    @Environment(AppStore.self) private var store

    @State private var selectedTab: RenterTab = .explore
    @State private var explorePath: [RenterRoute] = []
    @State private var reservationsPath: [RenterRoute] = []
    @State private var notificationsPath: [RenterRoute] = []

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Explore", systemImage: "magnifyingglass", value: RenterTab.explore) {
                NavigationStack(path: $explorePath) {
                    RenterHomeView(path: $explorePath)
                        .navigationDestination(for: RenterRoute.self) { route in
                            destination(for: route, path: $explorePath)
                        }
                }
            }

            Tab("Reservations", systemImage: "calendar", value: RenterTab.reservations) {
                NavigationStack(path: $reservationsPath) {
                    MyReservationsView(path: $reservationsPath)
                        .navigationDestination(for: RenterRoute.self) { route in
                            destination(for: route, path: $reservationsPath)
                        }
                }
            }
            .badge(store.renterBookingAlertCount)

            Tab("Notifications", systemImage: "bell", value: RenterTab.notifications) {
                NavigationStack(path: $notificationsPath) {
                    NotificationsView(role: .renter, isTabRoot: true, onOpenReservation: { id in
                        notificationsPath.append(renterRoute(forReservation: id))
                    })
                    .navigationDestination(for: RenterRoute.self) { route in
                        destination(for: route, path: $notificationsPath)
                    }
                }
            }
            .badge(store.unreadCount(for: .renter))

            Tab("Profile", systemImage: "person.crop.circle", value: RenterTab.profile) {
                NavigationStack {
                    ProfileView(role: .renter, isTabRoot: true)
                }
            }
        }
        .tint(Color.brandOrange)
        .minimizingTabBar()
    }

    @ViewBuilder
    private func destination(for route: RenterRoute, path: Binding<[RenterRoute]>) -> some View {
        switch route {
        case .searchResults(let query):
            SearchResultsView(query: query, path: path)
        case .spotDetails(let spotID, let query):
            SpotDetailsView(spotID: spotID, query: query, path: path)
        case .myReservations:
            MyReservationsView(path: path)
        case .reservationDetails(let id):
            ReservationDetailView(reservationID: id, role: .renter, path: path)
        case .requestDetails(let id):
            RequestDetailsView(reservationID: id, path: path)
        case .notifications:
            NotificationsView(role: .renter, onOpenReservation: { id in
                path.wrappedValue.append(renterRoute(forReservation: id))
            })
        case .profile:
            ProfileView(role: .renter)
        }
    }

    /// Pending reservations open the request-progress screen; everything else opens the detail screen.
    private func renterRoute(forReservation id: UUID) -> RenterRoute {
        if store.reservation(id: id)?.status == .pending {
            return .requestDetails(id)
        }
        return .reservationDetails(id)
    }
}
