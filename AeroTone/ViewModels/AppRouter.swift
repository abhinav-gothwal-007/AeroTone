import SwiftUI
import Observation

enum AppPage: Hashable {
    case welcome
    case homeAirport
    case destination
    case seat
    case boarding
    case flight
}

@MainActor
@Observable
final class AppRouter {
    var currentPage: AppPage = .welcome
    var homeAirport: Airport

    var selectedDestination: Airport?
    var selectedSeat: Seat?
    var passengerName: String = "Traveler"
    /// Explicit session length chosen in "By Time" mode; nil means use the route's flight time.
    var sessionDurationOverride: TimeInterval?

    var flightPlan: FlightPlan?
    var flightController: FlightController?
    let ambience = AmbienceMixer()

    var route: FlightRoute? {
        guard let dest = selectedDestination else { return nil }
        return FlightRoute(origin: homeAirport, destination: dest)
    }

    private let homeKey = "aerotone.homeAirport"
    private let nameKey = "aerotone.passengerName"

    init() {
        if let code = UserDefaults.standard.string(forKey: homeKey),
           let airport = Airport.find(code: code) {
            self.homeAirport = airport
        } else {
            self.homeAirport = Airport.defaultHome
        }
        if let name = UserDefaults.standard.string(forKey: nameKey), !name.isEmpty {
            self.passengerName = name
        } else if let fullName = NSFullUserName().split(separator: " ").first {
            self.passengerName = String(fullName)
        }
    }

    func setHome(_ airport: Airport) {
        homeAirport = airport
        UserDefaults.standard.set(airport.code, forKey: homeKey)
    }

    func setPassengerName(_ name: String) {
        passengerName = name.isEmpty ? "Traveler" : name
        UserDefaults.standard.set(passengerName, forKey: nameKey)
    }

    func go(to page: AppPage) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentPage = page
        }
    }

    func reset() {
        flightController?.endFlight()
        flightController = nil
        ambience.stop()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            currentPage = .welcome
            selectedDestination = nil
            selectedSeat = nil
            flightPlan = nil
            sessionDurationOverride = nil
        }
    }

    func confirmDestination(_ airport: Airport, customDuration: TimeInterval? = nil) {
        selectedDestination = airport
        sessionDurationOverride = customDuration
        go(to: .seat)
    }

    func confirmSeat(_ seat: Seat) {
        selectedSeat = seat
        if let route = route {
            flightPlan = FlightPlan(
                route: route,
                seat: seat,
                passengerName: passengerName,
                durationOverride: sessionDurationOverride
            )
        }
        go(to: .boarding)
    }

    func boardFlight() {
        if let plan = flightPlan, flightController == nil {
            flightController = FlightController(plan: plan)
        }
        go(to: .flight)
    }

    /// Indicates whether a flight is currently underway (running, paused, or completed but not dismissed).
    var hasActiveFlight: Bool {
        guard let c = flightController else { return false }
        return c.elapsed > 0 || c.isRunning
    }
}
