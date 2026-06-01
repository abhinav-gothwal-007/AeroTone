import Foundation

enum SeatClass: String, Codable, CaseIterable {
    case first
    case business
    case premium
    case economy

    var label: String {
        switch self {
        case .first: return "First"
        case .business: return "Business"
        case .premium: return "Premium Economy"
        case .economy: return "Economy"
        }
    }

    var perk: String {
        switch self {
        case .first: return "Lie-flat suite · chef's menu · onboard lounge"
        case .business: return "Lie-flat seat · priority boarding · lounge access"
        case .premium: return "Extra legroom · enhanced meals · larger screen"
        case .economy: return "Standard seat · complimentary refreshments"
        }
    }

    var accentName: String {
        switch self {
        case .first: return "first"
        case .business: return "business"
        case .premium: return "premium"
        case .economy: return "economy"
        }
    }
}

struct Seat: Identifiable, Hashable, Codable {
    let row: Int
    let column: String   // "A", "B", ...
    let seatClass: SeatClass
    let isAvailable: Bool

    var id: String { "\(row)\(column)" }
    var label: String { "\(row)\(column)" }
}

struct CabinSection: Identifiable {
    let id: String
    let seatClass: SeatClass
    let rowsRange: ClosedRange<Int>
    let columns: [String]    // e.g., ["A","B","","D","E","","F","G"] (empty string = aisle gap)

    var rows: [Int] { Array(rowsRange) }
    var seatColumns: [String] { columns.filter { !$0.isEmpty } }
}

struct CabinLayout {
    let sections: [CabinSection]

    /// Single-aisle narrow-body: a wider 2-2 cabin up front, standard 3-3 cabin in back.
    static let standard = CabinLayout(sections: [
        CabinSection(id: "front", seatClass: .business,
                     rowsRange: 1...4,
                     columns: ["A", "B", "", "C", "D"]),               // 2-2
        CabinSection(id: "main", seatClass: .economy,
                     rowsRange: 5...20,
                     columns: ["A", "B", "C", "", "D", "E", "F"])       // 3-3
    ])

    func allSeats(seedFor route: FlightRoute? = nil) -> [Seat] {
        var seats: [Seat] = []
        var seed = abs(route?.flightNumber.hashValue ?? 0)
        for section in sections {
            for row in section.rows {
                for col in section.seatColumns {
                    seed = (seed &* 1103515245 &+ 12345) & 0x7fffffff
                    let occupied = (seed % 100) < 35
                    seats.append(Seat(row: row, column: col, seatClass: section.seatClass, isAvailable: !occupied))
                }
            }
        }
        return seats
    }
}
