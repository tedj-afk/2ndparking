import SwiftUI
import PhotosUI

/// Modal sheet for editing the profile: photo, username, avatar color, bio and phone number.
struct EditProfileView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let role: AppRole

    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var phone: String = ""
    @State private var selectedStyle: AvatarStyle = .orange
    @State private var photoData: Data?
    @State private var pickerItem: PhotosPickerItem?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !phone.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 26) {
                    avatarSection

                    FormField(
                        label: "Username",
                        placeholder: "Your display name",
                        text: $name,
                        trailingIcon: "person",
                        keyboard: .default
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.inkPrimary)
                        TextField("Tell hosts a little about you", text: $bio, axis: .vertical)
                            .font(.system(size: 15))
                            .lineLimit(3...5)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .clipShape(.rect(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.borderGray, lineWidth: 1)
                            )
                    }

                    FormField(
                        label: "Phone Number",
                        placeholder: "+974 5X XX XX XX",
                        text: $phone,
                        trailingIcon: "phone",
                        keyboard: .phonePad
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "Save Changes", isEnabled: canSave) {
                    store.profileNames[role] = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    store.profileBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
                    store.profilePhone = phone.trimmingCharacters(in: .whitespaces)
                    store.avatarStyle = selectedStyle
                    if let photoData {
                        store.avatarImages[role] = photoData
                    } else {
                        store.avatarImages[role] = nil
                    }
                    dismiss()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .background(.regularMaterial)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.inkPrimary)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            name = store.displayName(for: role)
            bio = store.profileBio
            phone = store.profilePhone
            selectedStyle = store.avatarStyle
            photoData = store.avatarImages[role]
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        photoData = data
                    }
                }
            }
        }
    }

    private var avatarSection: some View {
        VStack(spacing: 16) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    AvatarCircle(
                        name: name.isEmpty ? store.displayName(for: role) : name,
                        size: 96,
                        foreground: selectedStyle.foreground,
                        background: selectedStyle.background,
                        imageData: photoData
                    )
                    .overlay(Circle().strokeBorder(selectedStyle.foreground.opacity(0.25), lineWidth: 2))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedStyle)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.brandOrange)
                        .clipShape(.circle)
                        .overlay(Circle().strokeBorder(Color.white, lineWidth: 2.5))
                        .offset(x: 3, y: 3)
                }
            }
            .buttonStyle(.plain)

            if photoData != nil {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        photoData = nil
                        pickerItem = nil
                    }
                } label: {
                    Text("Remove Photo")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.failureRed)
                }
            } else {
                HStack(spacing: 14) {
                    ForEach(AvatarStyle.allCases) { style in
                        Button {
                            selectedStyle = style
                        } label: {
                            Circle()
                                .fill(style.background)
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Circle()
                                        .fill(style.foreground)
                                        .frame(width: 15, height: 15)
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            selectedStyle == style ? Color.inkPrimary : Color.borderGray.opacity(0.6),
                                            lineWidth: selectedStyle == style ? 2 : 1
                                        )
                                )
                                .scaleEffect(selectedStyle == style ? 1.1 : 1)
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: selectedStyle)
                    }
                }

                Text("Tap the photo to upload, or pick an avatar color")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.inkTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
