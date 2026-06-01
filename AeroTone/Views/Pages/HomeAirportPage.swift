import SwiftUI

struct HomeAirportPage: View {
    @Bindable var router: AppRouter

    @State private var query: String = ""
    @State private var picked: Airport

    init(router: AppRouter) {
        self.router = router
        _picked = State(initialValue: router.homeAirport)
    }

    var body: some View {
        VStack(spacing: 12) {
            CompactHeader(title: "Home Airport", subtitle: "Every flight begins here", tint: .flowInk) {
                router.go(to: .welcome)
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
                TextField("Search city, code, country", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(red: 0.09, green: 0.12, blue: 0.24).opacity(0.5))
            )
            .glassPanel(cornerRadius: 14, elevation: 0.5)

            ScrollView {
                LazyVStack(spacing: 5) {
                    ForEach(filtered) { airport in
                        HomeAirportRow(airport: airport, isSelected: picked.id == airport.id) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                picked = airport
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }

            Button {
                router.setHome(picked)
                router.go(to: .welcome)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                    Text("Save · \(picked.code)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(PrimaryPillStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 26)
        .padding(.bottom, 16)
    }

    private var filtered: [Airport] {
        if query.isEmpty { return Airport.database }
        let q = query.lowercased()
        return Airport.database.filter {
            $0.code.lowercased().contains(q)
                || $0.city.lowercased().contains(q)
                || $0.country.lowercased().contains(q)
                || $0.name.lowercased().contains(q)
        }
    }
}

private struct HomeAirportRow: View {
    let airport: Airport
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
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background {
                let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
                ZStack {
                    shape.fill(.black.opacity(0.22))
                    if isSelected {
                        shape.fill(
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
}

struct CompactHeader: View {
    let title: String
    let subtitle: String?
    let tint: Color
    let onBack: (() -> Void)?

    init(title: String, subtitle: String? = nil, tint: Color = .white, onBack: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
        self.onBack = onBack
    }

    var body: some View {
        HStack(spacing: 10) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(tint)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle().fill(.white.opacity(0.12))
                        )
                        .overlay(
                            Circle().stroke(.white.opacity(0.2), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(tint)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(tint.opacity(0.7))
                }
            }
            Spacer()
        }
    }
}
