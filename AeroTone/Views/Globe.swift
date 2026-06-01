import SwiftUI
import MapKit

/// The in-flight map: an Apple Maps 3D imagery globe with the great-circle route,
/// origin/destination markers and the plane drawn on top. The camera defaults to
/// framing the flight, and the user can freely pan, spin and zoom.
struct GlobeView: View {
    let route: FlightRoute
    let progress: Double

    @State private var camera: MapCameraPosition

    init(route: FlightRoute, progress: Double) {
        self.route = route
        self.progress = progress
        _camera = State(initialValue: .camera(Self.framingCamera(for: route)))
    }

    private var originCoord: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: route.origin.latitude, longitude: route.origin.longitude)
    }
    private var destinationCoord: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: route.destination.latitude, longitude: route.destination.longitude)
    }

    /// Sampled great-circle path (reuses the slerp in `FlightRoute`).
    private func pathCoordinates(to fraction: Double) -> [CLLocationCoordinate2D] {
        let cap = max(0, min(1, fraction))
        let samples = 96
        var coords: [CLLocationCoordinate2D] = []
        coords.reserveCapacity(samples + 1)
        for i in 0...samples {
            let t = (Double(i) / Double(samples)) * cap
            let p = route.point(at: t)
            coords.append(CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude))
        }
        return coords
    }

    private var planeCoord: CLLocationCoordinate2D {
        let p = route.point(at: progress)
        return CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude)
    }

    /// Heading of the plane along the arc, in degrees.
    private var planeHeading: Double {
        let a = route.point(at: max(0, progress - 0.003))
        let b = route.point(at: min(1, progress + 0.003))
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let φ1 = a.latitude * .pi / 180
        let φ2 = b.latitude * .pi / 180
        let y = sin(dLon) * cos(φ2)
        let x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(dLon)
        return atan2(y, x) * 180 / .pi
    }

    var body: some View {
        Map(position: $camera, interactionModes: .all) {
            // Full route (dashed)
            MapPolyline(coordinates: pathCoordinates(to: 1))
                .stroke(
                    Color(red: 1.0, green: 0.7, blue: 0.4).opacity(0.85),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [4, 6])
                )

            // Travelled portion (solid)
            MapPolyline(coordinates: pathCoordinates(to: progress))
                .stroke(
                    Color(red: 0.5, green: 0.95, blue: 0.85),
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )

            Annotation(route.origin.code, coordinate: originCoord) {
                endpointDot(color: .white)
            }
            Annotation(route.destination.code, coordinate: destinationCoord) {
                endpointDot(color: progress >= 1 ? Color(red: 0.6, green: 1.0, blue: 0.7) : .white)
            }

            Annotation("", coordinate: planeCoord) {
                Image(systemName: "airplane")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(planeHeading - 90))
                    .shadow(color: .white.opacity(0.8), radius: 5)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 1)
            }
        }
        .mapStyle(.imagery(elevation: .realistic))
        .mapControlVisibility(.hidden)
    }

    private func endpointDot(color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 20, height: 20)
                .blur(radius: 3)
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
                .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 0.5))
        }
    }

    /// A camera centered on the route midpoint, kept far enough out that Apple Maps
    /// always renders the 3D globe (rather than zooming into a local map). Long-haul
    /// routes pull back a little further so both endpoints stay on the visible disc.
    private static func framingCamera(for route: FlightRoute) -> MapCamera {
        let mid = route.midpoint
        let meters = route.distanceKm * 1000
        // Minimum ~16,000 km keeps the Earth reading as a globe; scale up for long routes.
        let distance = min(max(meters * 2.0, 16_000_000), 42_000_000)
        return MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: mid.latitude, longitude: mid.longitude),
            distance: distance,
            heading: 0,
            pitch: 0
        )
    }
}
