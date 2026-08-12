import SwiftUI

/// Final signup step: pick the username and avatar shown across the app.
struct UsernameView: View {
    let onContinue: (String, AvatarStyle) -> Void

    @State private var name: String = ""
    @State private var selectedStyle: AvatarStyle = .orange
    @State private var appeared: Bool = false
    @FocusState private var nameFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canContinue: Bool { trimmedName.count >= 2 }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 10) {
                        Text("Almost there")
                            .font(.system(size: 12, weight: .bold))
                            .kerning(1.4)
                            .foregroundStyle(Color.brandOrange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orangeFaint)
                            .clipShape(.capsule)

                        Text("What should we call you?")
                            .font(.system(size: 27, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.inkPrimary)
                            .multilineTextAlignment(.center)

                        Text("This name appears on your bookings, access passes and messages with hosts.")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.inkSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.horizontal, 30)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .padding(.top, 18)

                    avatarPreview
                        .padding(.top, 30)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.86)

                    FormField(
                        label: "Username",
                        placeholder: "e.g. Nacer Lalaoui",
                        text: $name,
                        trailingIcon: "person"
                    )
                    .focused($nameFocused)
                    .padding(.horizontal, 16)
                    .padding(.top, 28)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                    colorPicker
                        .padding(.top, 26)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 24)
                }
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)

            VStack(spacing: 0) {
                PrimaryButton(title: "Continue", isEnabled: canContinue) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    nameFocused = false
                    onContinue(trimmedName, selectedStyle)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
            }
            .opacity(appeared ? 1 : 0)
        }
        .background(Color.white)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.86).delay(0.08)) {
                appeared = true
            }
        }
    }

    // MARK: - Avatar preview

    private var avatarPreview: some View {
        ZStack {
            Circle()
                .fill(selectedStyle.background.opacity(0.35))
                .frame(width: 148, height: 148)
                .blur(radius: 2)

            AvatarCircle(
                name: trimmedName.isEmpty ? "?" : trimmedName,
                size: 108,
                foreground: selectedStyle.foreground,
                background: selectedStyle.background,
                imageData: nil
            )
            .overlay(Circle().strokeBorder(Color.white, lineWidth: 4))
            .shadow(color: selectedStyle.foreground.opacity(0.22), radius: 14, y: 6)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: selectedStyle)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: trimmedName.isEmpty)
    }

    private var colorPicker: some View {
        VStack(spacing: 12) {
            Text("PICK YOUR AVATAR COLOR")
                .font(.system(size: 11, weight: .bold))
                .kerning(1)
                .foregroundStyle(Color.inkTertiary)

            HStack(spacing: 14) {
                ForEach(AvatarStyle.allCases) { style in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedStyle = style
                    } label: {
                        Circle()
                            .fill(style.background)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .fill(style.foreground)
                                    .frame(width: 16, height: 16)
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        selectedStyle == style ? Color.inkPrimary : Color.borderGray.opacity(0.6),
                                        lineWidth: selectedStyle == style ? 2 : 1
                                    )
                            )
                            .scaleEffect(selectedStyle == style ? 1.12 : 1)
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.72), value: selectedStyle)
                }
            }
        }
    }
}
