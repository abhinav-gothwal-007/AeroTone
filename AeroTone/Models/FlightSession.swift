import Foundation

enum FlightPhase: String, Codable {
    case boarding
    case takeoff
    case cruise
    case landing
    case arrived

    var label: String {
        switch self {
        case .boarding: return "Boarding"
        case .takeoff: return "Takeoff"
        case .cruise: return "Cruising"
        case .landing: return "Landing"
        case .arrived: return "Arrived"
        }
    }

    var systemImage: String {
        switch self {
        case .boarding: return "figure.walk.motion"
        case .takeoff: return "airplane.departure"
        case .cruise: return "airplane"
        case .landing: return "airplane.arrival"
        case .arrived: return "checkmark.seal.fill"
        }
    }
}
