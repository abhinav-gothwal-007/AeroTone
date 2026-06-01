import Foundation

struct FlightRoute: Hashable {
    let origin: Airport
    let destination: Airport

    /// Great-circle distance in kilometres.
    var distanceKm: Double {
        let earthR = 6371.0
        let dLat = (destination.latitude - origin.latitude).radians
        let dLon = (destination.longitude - origin.longitude).radians
        let φ1 = origin.latitude.radians
        let φ2 = destination.latitude.radians
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(φ1) * cos(φ2) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthR * c
    }

    var distanceMi: Double { distanceKm * 0.621371 }

    /// Estimated focus session duration. The math is calibrated so the shortest realistic flights
    /// (e.g., LHR→CDG, ~350 km) land near 15 min, and long-haul (e.g., LAX→SYD, ~12,000 km)
    /// land near ~3 hours — keeping sessions in pomodoro-friendly territory.
    var duration: TimeInterval {
        // 10 min taxi/climb/descent overhead + (distance / virtual cruise speed)
        // virtual cruise = ~3000 km/h (a compressed clock so distances feel meaningful
        // without forcing all-day focus sessions)
        let overhead: Double = 10 * 60
        let virtualCruise: Double = 3000
        let cruiseTime = (distanceKm / virtualCruise) * 3600
        return overhead + cruiseTime
    }

    var durationMinutes: Int { Int((duration / 60).rounded()) }

    /// Average cruise heading (in degrees from north), computed from origin → destination.
    var initialBearing: Double {
        let φ1 = origin.latitude.radians
        let φ2 = destination.latitude.radians
        let λ1 = origin.longitude.radians
        let λ2 = destination.longitude.radians
        let y = sin(λ2 - λ1) * cos(φ2)
        let x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(λ2 - λ1)
        let θ = atan2(y, x)
        return (θ.degrees + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Interpolate along the great-circle (slerp on the unit sphere) for 0...1.
    func point(at t: Double) -> (latitude: Double, longitude: Double) {
        let φ1 = origin.latitude.radians
        let φ2 = destination.latitude.radians
        let λ1 = origin.longitude.radians
        let λ2 = destination.longitude.radians

        // angular distance
        let d = acos(min(1, max(-1,
            sin(φ1) * sin(φ2) + cos(φ1) * cos(φ2) * cos(λ2 - λ1)
        )))
        if d < 1e-6 {
            return (origin.latitude, origin.longitude)
        }
        let A = sin((1 - t) * d) / sin(d)
        let B = sin(t * d) / sin(d)
        let x = A * cos(φ1) * cos(λ1) + B * cos(φ2) * cos(λ2)
        let y = A * cos(φ1) * sin(λ1) + B * cos(φ2) * sin(λ2)
        let z = A * sin(φ1) + B * sin(φ2)
        let φi = atan2(z, sqrt(x * x + y * y))
        let λi = atan2(y, x)
        return (φi.degrees, λi.degrees)
    }

    var midpoint: (latitude: Double, longitude: Double) {
        point(at: 0.5)
    }

    var flightNumber: String {
        let codes = origin.code + destination.code
        let hash = abs(codes.hashValue) % 9000
        return "AT \(100 + hash)"
    }

    var gate: String {
        let letters = ["A", "B", "C", "D", "E"]
        let letter = letters[abs(origin.code.hashValue) % letters.count]
        let number = (abs(destination.code.hashValue) % 25) + 1
        return "\(letter)\(number)"
    }

    var boardingTime: Date {
        Date().addingTimeInterval(20 * 60)
    }
}

private extension Double {
    var radians: Double { self * .pi / 180 }
    var degrees: Double { self * 180 / .pi }
}
