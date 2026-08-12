import SwiftUI

/// First-launch screen: pick which experience to preview.
struct RoleSwitcherView: View {
    @Environment(AppStore.self) private var store

    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)
            BrandLogo()
                .padding(.bottom, 28)

            Text("Choose a role to preview")
                .font(.pageTitle)
                .foregroundStyle(Color.inkPrimary)
            Text("Prototype build — every experience runs on mock data")
                .font(.helperText)
                .foregroundStyle(Color.inkSecondary)
                .padding(.top, 6)

            VStack(spacing: 14) {
                ForEach(Array(AppRole.allCases.enumerated()), id: \.element.id) { index, role in
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            store.activeRole = role
                        }
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: role.symbol)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Color.brandOrange)
                                .frame(width: 56, height: 56)
                                .background(Color.orangePale)
                                .clipShape(.rect(cornerRadius: 16))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(role.rawValue)
                                    .font(.system(size: 19, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.inkPrimary)
                                Text(role.subtitle)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.inkSecondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.inkTertiary)
                        }
                        .padding(16)
                        .background(Color.cardGray)
                        .clipShape(.rect(cornerRadius: 20))
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.08), value: appeared)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 32)

            Spacer()

            Text("2ndParking · Doha, Qatar")
                .font(.helperText)
                .foregroundStyle(Color.inkTertiary)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .onAppear { appeared = true }
    }
}
