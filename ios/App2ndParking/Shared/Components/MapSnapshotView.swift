import SwiftUI
import MapKit

/// Non-interactive static map snapshot with a brand-orange pin centered on the spot location.
struct MapSnapshotView: View {
    let latitude: Double
    let longitude: Double
    var height: CGFloat = 180

    @State private var snapshotImage: UIImage?
    @State private var snapshotFailed: Bool = false

    var body: some View {
        Color.cardGray
            .frame(height: height)
            .overlay {
                if let snapshotImage {
                    Image(uiImage: snapshotImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                } else if snapshotFailed {
                    VStack(spacing: 8) {
                        Image(systemName: "map")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.placeholderGray)
                        Text("Map unavailable")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.inkSecondary)
                    }
                } else {
                    ProgressView()
                        .tint(Color.brandOrange)
                }
            }
            .clipShape(.rect(cornerRadius: 16))
            .overlay {
                if snapshotImage != nil {
                    pin
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
            }
            .animation(.easeOut(duration: 0.25), value: snapshotImage != nil)
            .task(id: taskID) {
                await makeSnapshot()
            }
    }

    private var taskID: String {
        "\(latitude),\(longitude)"
    }

    /// Pin drawn in SwiftUI so the tip sits exactly on the centered coordinate.
    private var pin: some View {
        VStack(spacing: -3) {
            ZStack {
                Circle()
                    .fill(Color.brandOrange)
                    .frame(width: 34, height: 34)
                    .shadow(color: .black.opacity(0.25), radius: 5, y: 2)
                Image(systemName: "parkingsign")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            Triangle()
                .fill(Color.brandOrange)
                .frame(width: 14, height: 10)
                .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
        }
        .offset(y: -21)
        .allowsHitTesting(false)
    }

    private func makeSnapshot() async {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )
        options.size = CGSize(width: 800, height: 440)
        options.pointOfInterestFilter = .includingAll
        options.showsBuildings = true

        let snapshotter = MKMapSnapshotter(options: options)
        do {
            let snapshot = try await snapshotter.start()
            snapshotImage = snapshot.image
            snapshotFailed = false
        } catch {
            print("Map snapshot failed: \(error.localizedDescription)")
            snapshotFailed = true
        }
    }
}

/// Downward-pointing triangle used as the pin tail.
struct Triangle: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
