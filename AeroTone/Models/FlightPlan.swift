import Foundation

struct FlightPlan: Hashable {
    let route: FlightRoute
    let seat: Seat
    let flightNumber: String
    let gate: String
    let boardingTime: Date
    let passengerName: String
    /// When set (e.g. the user chose a specific focus length in "By Time" mode), this
    /// is the session length instead of the distance-derived flight time.
    let durationOverride: TimeInterval?

    init(route: FlightRoute, seat: Seat, passengerName: String = "Traveler", durationOverride: TimeInterval? = nil) {
        self.route = route
        self.seat = seat
        self.flightNumber = route.flightNumber
        self.gate = route.gate
        self.boardingTime = route.boardingTime
        self.passengerName = passengerName.uppercased()
        self.durationOverride = durationOverride
    }

    var duration: TimeInterval { durationOverride ?? route.duration }
}
