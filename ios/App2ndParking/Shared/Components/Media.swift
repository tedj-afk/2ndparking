import SwiftUI
import CoreImage.CIFilterBuiltins

/// Fill-mode photo that never overflows layout: Color anchor + overlay image.
struct SpotPhoto: View {
    let name: String

    var body: some View {
        Color.fieldGray
            .overlay {
                if let uiImage = UIImage(named: name) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                } else {
                    Image(systemName: "car.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.placeholderGray)
                        .allowsHitTesting(false)
                }
            }
            .clipped()
    }
}

/// Full-bleed swipeable photo carousel with page dots, "1/5" counter and overlay buttons.
struct ImageCarousel: View {
    let photos: [String]
    var height: CGFloat = 290
    var onBack: (() -> Void)? = nil
    var onMore: (() -> Void)? = nil

    @State private var page: Int = 0

    var body: some View {
        TabView(selection: $page) {
            ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                SpotPhoto(name: photo)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: height)
        .clipped()
        .overlay(alignment: .bottom) {
            HStack(spacing: 6) {
                ForEach(0..<photos.count, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(index == page ? 1 : 0.5))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.bottom, 14)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: page)
        }
        .overlay(alignment: .bottomTrailing) {
            Text("\(page + 1)/\(photos.count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.black.opacity(0.35))
                .clipShape(.capsule)
                .padding(12)
        }
        .overlay(alignment: .topLeading) {
            if let onBack {
                GlassCircleButton(systemName: "chevron.left", action: onBack)
                    .padding(.horizontal, 16)
                    .padding(.top, 56)
            }
        }
        .overlay(alignment: .topTrailing) {
            if let onMore {
                GlassCircleButton(systemName: "ellipsis", action: onMore)
                    .padding(.horizontal, 16)
                    .padding(.top, 56)
            }
        }
    }
}

/// Real scannable QR code rendered from a payload string via CoreImage.
struct QRCodeView: View {
    let payload: String

    @State private var qrImage: UIImage?

    var body: some View {
        Group {
            if let qrImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.fieldGray
            }
        }
        .onAppear { generate() }
    }

    private func generate() {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return }
        qrImage = UIImage(cgImage: cgImage)
    }
}

/// Avatar circle with initials (host rows, request screens) or a custom photo when provided.
struct AvatarCircle: View {
    let name: String
    var size: CGFloat = 36
    var foreground: Color = .brandOrange
    var background: Color = .orangePale
    /// Optional custom photo; shown instead of the initials when set.
    var imageData: Data? = nil

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)) }.joined()
    }

    var body: some View {
        if let imageData, let uiImage = UIImage(data: imageData) {
            Color.clear
                .frame(width: size, height: size)
                .overlay {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                }
                .clipShape(.circle)
        } else {
            Text(initials.uppercased())
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(foreground)
                .frame(width: size, height: size)
                .background(background)
                .clipShape(.circle)
        }
    }
}

/// Host row: avatar + name + orange verified badge, rating on the right.
struct HostRow: View {
    let name: String
    let verified: Bool
    let rating: Double
    let reviewCount: Int

    var body: some View {
        HStack(spacing: 10) {
            AvatarCircle(name: name)
            Text(name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.inkPrimary)
            if verified {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.brandOrange)
            }
            Spacer()
            RatingLabel(rating: rating, count: reviewCount)
        }
    }
}
