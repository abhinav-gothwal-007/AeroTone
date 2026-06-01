import Foundation

struct Airport: Identifiable, Hashable, Codable {
    let code: String       // IATA
    let name: String
    let city: String
    let country: String
    let region: String     // for grouping
    let latitude: Double
    let longitude: Double

    var id: String { code }

    var displayName: String { "\(city), \(country)" }
    var shortName: String { "\(city) (\(code))" }
}

extension Airport {
    /// Loaded once from the bundled `airports.csv` (OurAirports data, public domain:
    /// large airports worldwide that have an IATA code).
    static let database: [Airport] = loadDatabase()

    private static func loadDatabase() -> [Airport] {
        guard let url = Bundle.main.url(forResource: "airports", withExtension: "csv"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else {
            assertionFailure("airports.csv missing from bundle")
            return fallbackDatabase
        }

        var airports: [Airport] = []
        var isHeader = true
        raw.enumerateLines { line, _ in
            if isHeader { isHeader = false; return }   // skip column header
            if line.isEmpty { return }
            let f = parseCSVLine(line)
            guard f.count == 7,
                  let lat = Double(f[5]), let lon = Double(f[6]) else { return }
            airports.append(Airport(code: f[0], name: f[1], city: f[2],
                                    country: f[3], region: f[4],
                                    latitude: lat, longitude: lon))
        }
        return airports.isEmpty ? fallbackDatabase : airports
    }

    /// Minimal CSV field parser supporting double-quoted fields with embedded commas
    /// and escaped quotes (`""`). Sufficient for the airports dataset.
    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var chars = Array(line)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        current.append("\""); i += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(c)
                }
            } else {
                switch c {
                case "\"": inQuotes = true
                case ",":  fields.append(current); current = ""
                default:   current.append(c)
                }
            }
            i += 1
        }
        fields.append(current)
        return fields
    }

    /// Tiny safety net used only if the bundled CSV can't be read.
    private static let fallbackDatabase: [Airport] = [
        // North America
        Airport(code: "JFK", name: "John F. Kennedy International", city: "New York", country: "USA", region: "North America", latitude: 40.6413, longitude: -73.7781),
        Airport(code: "LGA", name: "LaGuardia", city: "New York", country: "USA", region: "North America", latitude: 40.7769, longitude: -73.8740),
        Airport(code: "LAX", name: "Los Angeles International", city: "Los Angeles", country: "USA", region: "North America", latitude: 33.9416, longitude: -118.4085),
        Airport(code: "SFO", name: "San Francisco International", city: "San Francisco", country: "USA", region: "North America", latitude: 37.6213, longitude: -122.3790),
        Airport(code: "ORD", name: "O'Hare International", city: "Chicago", country: "USA", region: "North America", latitude: 41.9742, longitude: -87.9073),
        Airport(code: "ATL", name: "Hartsfield-Jackson", city: "Atlanta", country: "USA", region: "North America", latitude: 33.6407, longitude: -84.4277),
        Airport(code: "DFW", name: "Dallas/Fort Worth", city: "Dallas", country: "USA", region: "North America", latitude: 32.8998, longitude: -97.0403),
        Airport(code: "SEA", name: "Seattle-Tacoma", city: "Seattle", country: "USA", region: "North America", latitude: 47.4502, longitude: -122.3088),
        Airport(code: "BOS", name: "Boston Logan", city: "Boston", country: "USA", region: "North America", latitude: 42.3656, longitude: -71.0096),
        Airport(code: "MIA", name: "Miami International", city: "Miami", country: "USA", region: "North America", latitude: 25.7959, longitude: -80.2870),
        Airport(code: "DEN", name: "Denver International", city: "Denver", country: "USA", region: "North America", latitude: 39.8561, longitude: -104.6737),
        Airport(code: "YYZ", name: "Toronto Pearson", city: "Toronto", country: "Canada", region: "North America", latitude: 43.6777, longitude: -79.6248),
        Airport(code: "YVR", name: "Vancouver International", city: "Vancouver", country: "Canada", region: "North America", latitude: 49.1967, longitude: -123.1815),
        Airport(code: "MEX", name: "Benito Juárez", city: "Mexico City", country: "Mexico", region: "North America", latitude: 19.4361, longitude: -99.0719),

        // Europe
        Airport(code: "LHR", name: "Heathrow", city: "London", country: "UK", region: "Europe", latitude: 51.4700, longitude: -0.4543),
        Airport(code: "LGW", name: "Gatwick", city: "London", country: "UK", region: "Europe", latitude: 51.1537, longitude: -0.1821),
        Airport(code: "CDG", name: "Charles de Gaulle", city: "Paris", country: "France", region: "Europe", latitude: 49.0097, longitude: 2.5479),
        Airport(code: "AMS", name: "Schiphol", city: "Amsterdam", country: "Netherlands", region: "Europe", latitude: 52.3105, longitude: 4.7683),
        Airport(code: "FRA", name: "Frankfurt am Main", city: "Frankfurt", country: "Germany", region: "Europe", latitude: 50.0379, longitude: 8.5622),
        Airport(code: "MUC", name: "Munich", city: "Munich", country: "Germany", region: "Europe", latitude: 48.3537, longitude: 11.7861),
        Airport(code: "MAD", name: "Barajas", city: "Madrid", country: "Spain", region: "Europe", latitude: 40.4983, longitude: -3.5676),
        Airport(code: "BCN", name: "El Prat", city: "Barcelona", country: "Spain", region: "Europe", latitude: 41.2974, longitude: 2.0833),
        Airport(code: "FCO", name: "Fiumicino", city: "Rome", country: "Italy", region: "Europe", latitude: 41.8003, longitude: 12.2389),
        Airport(code: "ZRH", name: "Zurich", city: "Zurich", country: "Switzerland", region: "Europe", latitude: 47.4647, longitude: 8.5492),
        Airport(code: "VIE", name: "Vienna International", city: "Vienna", country: "Austria", region: "Europe", latitude: 48.1103, longitude: 16.5697),
        Airport(code: "CPH", name: "Copenhagen", city: "Copenhagen", country: "Denmark", region: "Europe", latitude: 55.6180, longitude: 12.6560),
        Airport(code: "ARN", name: "Arlanda", city: "Stockholm", country: "Sweden", region: "Europe", latitude: 59.6519, longitude: 17.9186),
        Airport(code: "IST", name: "Istanbul", city: "Istanbul", country: "Turkey", region: "Europe", latitude: 41.2753, longitude: 28.7519),

        // Middle East & Africa
        Airport(code: "DXB", name: "Dubai International", city: "Dubai", country: "UAE", region: "Middle East", latitude: 25.2532, longitude: 55.3657),
        Airport(code: "DOH", name: "Hamad International", city: "Doha", country: "Qatar", region: "Middle East", latitude: 25.2731, longitude: 51.6080),
        Airport(code: "JNB", name: "O.R. Tambo", city: "Johannesburg", country: "South Africa", region: "Africa", latitude: -26.1392, longitude: 28.2460),
        Airport(code: "CPT", name: "Cape Town International", city: "Cape Town", country: "South Africa", region: "Africa", latitude: -33.9719, longitude: 18.6021),
        Airport(code: "CAI", name: "Cairo International", city: "Cairo", country: "Egypt", region: "Africa", latitude: 30.1219, longitude: 31.4056),

        // Asia
        Airport(code: "SIN", name: "Changi", city: "Singapore", country: "Singapore", region: "Asia", latitude: 1.3644, longitude: 103.9915),
        Airport(code: "HKG", name: "Hong Kong International", city: "Hong Kong", country: "China", region: "Asia", latitude: 22.3080, longitude: 113.9185),
        Airport(code: "NRT", name: "Narita", city: "Tokyo", country: "Japan", region: "Asia", latitude: 35.7720, longitude: 140.3929),
        Airport(code: "HND", name: "Haneda", city: "Tokyo", country: "Japan", region: "Asia", latitude: 35.5494, longitude: 139.7798),
        Airport(code: "ICN", name: "Incheon", city: "Seoul", country: "South Korea", region: "Asia", latitude: 37.4602, longitude: 126.4407),
        Airport(code: "PEK", name: "Beijing Capital", city: "Beijing", country: "China", region: "Asia", latitude: 40.0801, longitude: 116.5846),
        Airport(code: "PVG", name: "Pudong", city: "Shanghai", country: "China", region: "Asia", latitude: 31.1443, longitude: 121.8083),
        Airport(code: "BKK", name: "Suvarnabhumi", city: "Bangkok", country: "Thailand", region: "Asia", latitude: 13.6900, longitude: 100.7501),
        Airport(code: "DEL", name: "Indira Gandhi", city: "Delhi", country: "India", region: "Asia", latitude: 28.5562, longitude: 77.1000),
        Airport(code: "BOM", name: "Chhatrapati Shivaji", city: "Mumbai", country: "India", region: "Asia", latitude: 19.0896, longitude: 72.8656),

        // Oceania & South America
        Airport(code: "SYD", name: "Kingsford Smith", city: "Sydney", country: "Australia", region: "Oceania", latitude: -33.9399, longitude: 151.1753),
        Airport(code: "MEL", name: "Tullamarine", city: "Melbourne", country: "Australia", region: "Oceania", latitude: -37.6690, longitude: 144.8410),
        Airport(code: "AKL", name: "Auckland", city: "Auckland", country: "New Zealand", region: "Oceania", latitude: -37.0082, longitude: 174.7850),
        Airport(code: "GRU", name: "Guarulhos", city: "São Paulo", country: "Brazil", region: "South America", latitude: -23.4356, longitude: -46.4731),
        Airport(code: "EZE", name: "Ezeiza", city: "Buenos Aires", country: "Argentina", region: "South America", latitude: -34.8222, longitude: -58.5358),
        Airport(code: "SCL", name: "Arturo Merino Benítez", city: "Santiago", country: "Chile", region: "South America", latitude: -33.3928, longitude: -70.7858),
    ]

    static func find(code: String) -> Airport? {
        database.first { $0.code == code }
    }

    static let defaultHome: Airport = find(code: "SFO")!
}
