import SwiftUI

struct DestinationPage: View {
    @Bindable var router: AppRouter

    enum Mode: String, CaseIterable, Identifiable {
        case bySearch, byDuration
        var id: String { rawValue }
        var label: String { self == .bySearch ? "Search" : "By Time" }
        var icon: String { self == .bySearch ? "magnifyingglass" : "clock.fill" }
    }

    @State private var mode: Mode = .bySearch
    @State private var searchQuery: String = ""
    @State private var desiredMinutes: Double = 25
    @State private var preview: Airport?

    /// Quick-pick focus lengths (minutes) and the bounds for the fine stepper.
    private static let presets: [Int] = [15, 25, 30, 45, 60, 90, 120, 180]
    private static let minMinutes: Double = 5
    private static let maxMinutes: Double = 360

    var body: some View {
        VStack(spacing: 12) {
            CompactHeader(
                title: "Where to?",
                subtitle: "Departing \(router.homeAirport.code) · \(router.homeAirport.city)",
                tint: .flowInk
            ) {
                router.go(to: .welcome)
            }

            modeSwitch

            ZStack {
                if mode == .bySearch {
                    searchMode
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                } else {
                    durationMode
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: mode)

            if let preview = preview {
                confirmBar(airport: preview)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 26)
        .padding(.bottom, 16)
    }

    private var modeSwitch: some View {
        HStack(spacing: 4) {
            ForEach(Mode.allCases) { m in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        mode = m
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: m.icon)
                            .font(.system(size: 10, weight: .semibold))
                        Text(m.label)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(mode == m ? .black.opacity(0.85) : .white.opacity(0.75))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background {
                        if mode == m {
                            Capsule(style: .continuous).fill(.white.opacity(0.95))
                                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .glassPanel(cornerRadius: 18, elevation: 0.6)
    }

    private var searchMode: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
                TextField("City, airport, or code", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                if !searchQuery.isEmpty {
                    Button { searchQuery = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .glassPanel(cornerRadius: 14, elevation: 0.5)

            airportList(filteredAirports)
        }
    }

    private var durationMode: some View {
        VStack(spacing: 10) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Text("Focus for")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    stepButton("minus") { adjust(-5) }
                    Text(formatDuration(desiredMinutes))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .frame(minWidth: 72)
                        .contentTransition(.numericText())
                    stepButton("plus") { adjust(5) }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Self.presets, id: \.self) { preset in
                            presetChip(preset)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            .padding(12)
            .glassPanel(cornerRadius: 16, elevation: 0.6)

            HStack {
                Text("Choose your destination")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .kerning(1.0)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
            }
            .padding(.horizontal, 4)

            airportList(recommendedAirports)
        }
    }

    private func stepButton(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(.white.opacity(0.14)))
                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func presetChip(_ minutes: Int) -> some View {
        let selected = Int(desiredMinutes) == minutes
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                desiredMinutes = Double(minutes)
            }
        } label: {
            Text(chipLabel(minutes))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(selected ? .black.opacity(0.85) : .white.opacity(0.8))
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(selected ? Color.white.opacity(0.95) : Color.white.opacity(0.10))
                )
                .overlay(
                    Capsule().stroke(.white.opacity(selected ? 0 : 0.15), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    private func chipLabel(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60
        let r = minutes % 60
        return r == 0 ? "\(h)h" : "\(h)h\(r)"
    }

    private func adjust(_ delta: Double) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            desiredMinutes = min(Self.maxMinutes, max(Self.minMinutes, desiredMinutes + delta))
        }
    }

    private func airportList(_ airports: [Airport]) -> some View {
        ScrollView {
            LazyVStack(spacing: 5) {
                ForEach(airports) { airport in
                    AirportRow(
                        airport: airport,
                        route: FlightRoute(origin: router.homeAirport, destination: airport),
                        isSelected: preview?.id == airport.id
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            preview = airport
                        }
                    }
                }
            }
            .padding(.horizontal, 1)
            .padding(.bottom, 4)
        }
    }

    private func confirmBar(airport: Airport) -> some View {
        let route = FlightRoute(origin: router.homeAirport, destination: airport)
        let isByTime = mode == .byDuration
        let sessionSeconds = isByTime ? desiredMinutes * 60 : route.duration
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(router.homeAirport.code)
                    Image(systemName: "airplane")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.55))
                    Text(airport.code)
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                Text("\(formatRouteDuration(sessionSeconds)) focus")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            Button {
                router.confirmDestination(airport, customDuration: isByTime ? sessionSeconds : nil)
            } label: {
                HStack(spacing: 5) {
                    Text("Seat")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(PrimaryPillStyle())
        }
        .padding(10)
        .glassPanel(cornerRadius: 18, elevation: 1.2)
    }

    private var filteredAirports: [Airport] {
        let candidates = Airport.database.filter { $0.code != router.homeAirport.code }
        guard !searchQuery.isEmpty else {
            return candidates.sorted { a, b in
                FlightRoute(origin: router.homeAirport, destination: a).distanceKm
                    < FlightRoute(origin: router.homeAirport, destination: b).distanceKm
            }
        }
        let q = searchQuery.lowercased()
        return candidates.filter {
            $0.code.lowercased().contains(q)
                || $0.city.lowercased().contains(q)
                || $0.country.lowercased().contains(q)
                || $0.name.lowercased().contains(q)
        }
    }

    private var recommendedAirports: [Airport] {
        let target = desiredMinutes * 60
        let scored = Airport.database
            .filter { $0.code != router.homeAirport.code }
            .map { ($0, FlightRoute(origin: router.homeAirport, destination: $0)) }
            .sorted { abs($0.1.duration - target) < abs($1.1.duration - target) }
        return Array(scored.prefix(8)).map { $0.0 }
    }

    private func formatDuration(_ minutes: Double) -> String {
        let m = Int(minutes)
        if m < 60 { return "\(m) min" }
        let h = m / 60
        let rem = m % 60
        if rem == 0 { return "\(h)h" }
        return "\(h)h \(rem)m"
    }

    private func formatRouteDuration(_ seconds: TimeInterval) -> String {
        let m = Int(seconds / 60)
        if m < 60 { return "\(m) min" }
        let h = m / 60
        let rem = m % 60
        if rem == 0 { return "\(h)h" }
        return "\(h)h \(rem)m"
    }
}

private struct AirportRow: View {
    let airport: Airport
    let route: FlightRoute
    let isSelected: Bool
    let action: () -> Void

    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(airport.code)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.white.opacity(isSelected ? 0.22 : 0.10))
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(airport.city)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(airport.country)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(formatDuration(route.duration))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text("\(Int(route.distanceKm.rounded()).formatted()) km")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background {
                let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
                ZStack {
                    // Persistent dark backing so white text stays legible over bright sky.
                    shape.fill(.black.opacity(0.22))
                    if isSelected {
                        shape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.40, green: 0.62, blue: 1.0).opacity(0.55),
                                        Color(red: 0.6, green: 0.5, blue: 1.0).opacity(0.40)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else if hover {
                        shape.fill(.white.opacity(0.08))
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected ? .white.opacity(0.55) : .white.opacity(0.12),
                        lineWidth: isSelected ? 0.9 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let m = Int(seconds / 60)
        if m < 60 { return "\(m) min" }
        let h = m / 60
        let rem = m % 60
        if rem == 0 { return "\(h)h" }
        return "\(h)h \(rem)m"
    }
}

struct PrimaryPillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.black.opacity(0.85))
            .background(
                Capsule(style: .continuous).fill(.white.opacity(0.95))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(.white.opacity(0.45), lineWidth: 0.5)
                    .blendMode(.plusLighter)
            )
            .clipShape(Capsule(style: .continuous))
            .shadow(color: .white.opacity(0.25), radius: 8)
            .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
