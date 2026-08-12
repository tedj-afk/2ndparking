import SwiftUI
import CoreLocation

/// Publishes the user's current location for distance calculations.
/// Falls back to a central Doha reference point (Souq Waqif area) when
/// permission is denied, unavailable, or the device fix is far outside Qatar
/// (e.g. cloud simulator defaults), so the prototype always shows realistic distances.
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    /// Central Doha fallback so demo distances stay realistic.
    static let dohaFallback = CLLocation(latitude: 25.2867, longitude: 51.5333)

    /// Fixes farther than this from Doha are treated as non-representative (simulator defaults).
    private static let plausibleRadiusMeters: CLLocationDistance = 300_000

    private let manager = CLLocationManager()

    private(set) var currentLocation: CLLocation = LocationService.dohaFallback
    private(set) var isUsingFallback: Bool = true

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    /// Distance in kilometers from the user (or Doha fallback) to a spot.
    func distanceKm(latitude: Double, longitude: Double) -> Double {
        let spotLocation = CLLocation(latitude: latitude, longitude: longitude)
        return currentLocation.distance(from: spotLocation) / 1000
    }

    /// "650 m" under 1 km, otherwise "2.4 km".
    func distanceLabel(latitude: Double, longitude: Double) -> String {
        let km = distanceKm(latitude: latitude, longitude: longitude)
        if km < 1 {
            return "\(Int((km * 1000).rounded())) m"
        }
        return String(format: "%.1f km", km)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let fix = locations.last else { return }
        Task { @MainActor in
            if fix.distance(from: Self.dohaFallback) <= Self.plausibleRadiusMeters {
                self.currentLocation = fix
                self.isUsingFallback = false
            } else {
                self.currentLocation = Self.dohaFallback
                self.isUsingFallback = true
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location fix failed, using Doha fallback: \(error.localizedDescription)")
    }
}
