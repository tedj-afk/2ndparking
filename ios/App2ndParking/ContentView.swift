import SwiftUI

/// Launch sequence phases before the main app.
enum LaunchPhase {
    case splash
    case onboarding
    case welcome
    case username
    case ready
}

/// App root: splash → onboarding slides → welcome (sign-up) → username → role switcher → role experience.
struct ContentView: View {
    @State private var store = AppStore()
    @State private var locationService = LocationService()
    @State private var phase: LaunchPhase = .splash

    var body: some View {
        Group {
            switch phase {
            case .splash:
                SplashView {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        phase = .onboarding
                    }
                }
                .transition(.opacity)
            case .onboarding:
                OnboardingView {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                        phase = .welcome
                    }
                }
                .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
            case .welcome:
                WelcomeView {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                        phase = .username
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            case .username:
                UsernameView { name, style in
                    store.applySignupProfile(name: name, style: style)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                        phase = .ready
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            case .ready:
                mainApp
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .environment(store)
        .environment(locationService)
    }

    private var mainApp: some View {
        Group {
            switch store.activeRole {
            case .none:
                RoleSwitcherView()
                    .transition(.opacity)
            case .renter:
                RenterRootView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .lister:
                ListerRootView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .security:
                SecurityRootView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: store.activeRole)
    }
}

#Preview {
    ContentView()
}
