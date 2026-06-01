import SwiftUI

struct BoardingPassView: View {
    let plan: FlightPlan
    /// 0…1, drives the staggered section reveal animation
    let revealProgress: Double

    var body: some View {
        VStack(spacing: 0) {
            header

            mainBlock

            Spacer(minLength: 6)

            dottedSeparator

            Spacer(minLength: 6)

            stub

            barcode
        }
        .frame(width: 288, height: 332)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.97, blue: 0.99),
                    Color(red: 0.89, green: 0.91, blue: 0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.5), lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 20, y: 10)
        .shadow(color: .black.opacity(0.16), radius: 36, y: 20)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.18, green: 0.30, blue: 0.55),
                                    Color(red: 0.10, green: 0.18, blue: 0.40)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 20, height: 20)
                    Image(systemName: "airplane")
                        .font(.system(size: 8, weight: .black))
                        .rotationEffect(.degrees(-20))
                        .foregroundStyle(.white)
                }
                Text("AeroTone Airways")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.8))
            }
            Spacer()
            Text("BOARDING PASS")
                .font(.system(size: 7.5, weight: .bold, design: .rounded))
                .kerning(1.6)
                .foregroundStyle(.black.opacity(0.45))
        }
        .padding(.horizontal, 16)
        .padding(.top, 13)
        .padding(.bottom, 8)
        .reveal(at: 0.05, progress: revealProgress)
    }

    // MARK: - Main block

    private var mainBlock: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("FROM")
                        .font(.system(size: 7.5, weight: .bold, design: .rounded))
                        .kerning(1.3)
                        .foregroundStyle(.black.opacity(0.4))
                    Text(plan.route.origin.code)
                        .font(.system(size: 27, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.85))
                    Text(plan.route.origin.city)
                        .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.55))
                        .lineLimit(1)
                }

                VStack(spacing: 3) {
                    Image(systemName: "airplane")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black.opacity(0.35))
                    Rectangle()
                        .fill(.black.opacity(0.15))
                        .frame(height: 1)
                    Text(formatDuration(plan.duration))
                        .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.45))
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .trailing, spacing: 1) {
                    Text("TO")
                        .font(.system(size: 7.5, weight: .bold, design: .rounded))
                        .kerning(1.3)
                        .foregroundStyle(.black.opacity(0.4))
                    Text(plan.route.destination.code)
                        .font(.system(size: 27, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.85))
                    Text(plan.route.destination.city)
                        .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.55))
                        .lineLimit(1)
                }
            }
            .reveal(at: 0.18, progress: revealProgress)

            HStack {
                field("PASSENGER", plan.passengerName)
                Spacer()
                field("CLASS", shortClass(plan.seat.seatClass))
            }
            .reveal(at: 0.34, progress: revealProgress)

            HStack {
                field("DATE", Date(), format: .dateTime.day().month(.abbreviated))
                Spacer()
                field("FLIGHT", plan.flightNumber)
            }
            .reveal(at: 0.42, progress: revealProgress)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Separator

    private var dottedSeparator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(.black.opacity(0.18))
                .frame(width: 13, height: 13)
                .offset(x: -8)
            HStack(spacing: 5) {
                ForEach(0..<20, id: \.self) { _ in
                    Rectangle()
                        .fill(.black.opacity(0.18))
                        .frame(width: 4, height: 1)
                }
            }
            Circle()
                .fill(.black.opacity(0.18))
                .frame(width: 13, height: 13)
                .offset(x: 8)
        }
        .reveal(at: 0.5, progress: revealProgress)
    }

    // MARK: - Stub (large seat + gate row)

    private var stub: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("SEAT")
                    .font(.system(size: 7.5, weight: .bold, design: .rounded))
                    .kerning(1.3)
                    .foregroundStyle(.black.opacity(0.45))
                Text(plan.seat.label)
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.85))
            }
            Spacer()
            VStack(alignment: .leading, spacing: 1) {
                Text("GATE")
                    .font(.system(size: 7.5, weight: .bold, design: .rounded))
                    .kerning(1.3)
                    .foregroundStyle(.black.opacity(0.45))
                Text(plan.gate)
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.85))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("BOARDS")
                    .font(.system(size: 7.5, weight: .bold, design: .rounded))
                    .kerning(1.3)
                    .foregroundStyle(.black.opacity(0.45))
                Text(plan.boardingTime, format: .dateTime.hour().minute())
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .monospaced()
                    .foregroundStyle(.black.opacity(0.85))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .reveal(at: 0.6, progress: revealProgress)
    }

    // MARK: - Barcode

    private var barcode: some View {
        BarcodeView(seed: plan.flightNumber + plan.seat.id)
            .frame(height: 32)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 14)
            .opacity(min(1, max(0, (revealProgress - 0.7) * 5)))
    }

    // MARK: - Helpers

    private func field(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 7.5, weight: .bold, design: .rounded))
                .kerning(1.2)
                .foregroundStyle(.black.opacity(0.45))
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.black.opacity(0.8))
                .lineLimit(1)
        }
    }

    private func field(_ label: String, _ value: Date, format: Date.FormatStyle) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 7.5, weight: .bold, design: .rounded))
                .kerning(1.2)
                .foregroundStyle(.black.opacity(0.45))
            Text(value, format: format)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.black.opacity(0.8))
        }
    }

    private func shortClass(_ sc: SeatClass) -> String {
        switch sc {
        case .first: return "First"
        case .business: return "Business"
        case .premium: return "Premium"
        case .economy: return "Economy"
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let m = Int(seconds / 60)
        if m < 60 { return "\(m)m" }
        let h = m / 60
        let rem = m % 60
        if rem == 0 { return "\(h)h" }
        return "\(h)h \(rem)m"
    }
}

private struct RevealModifier: ViewModifier {
    let threshold: Double
    let progress: Double

    func body(content: Content) -> some View {
        let local = max(0, min(1, (progress - threshold) * 5))
        content
            .opacity(local)
            .offset(y: (1 - local) * 4)
    }
}

private extension View {
    func reveal(at threshold: Double, progress: Double) -> some View {
        modifier(RevealModifier(threshold: threshold, progress: progress))
    }
}

private struct BarcodeView: View {
    let seed: String

    var body: some View {
        GeometryReader { geo in
            let widths = bars(in: seed)
            let totalWeight = widths.reduce(0, +)
            let pixelPerWeight = geo.size.width / CGFloat(totalWeight)
            HStack(spacing: 1) {
                ForEach(Array(widths.enumerated()), id: \.offset) { i, w in
                    Rectangle()
                        .fill(i % 2 == 0 ? Color.black.opacity(0.8) : .clear)
                        .frame(width: CGFloat(w) * pixelPerWeight)
                }
            }
        }
    }

    private func bars(in seed: String) -> [Int] {
        let bytes = Array(seed.utf8)
        var widths: [Int] = []
        var n = bytes.reduce(0) { ($0 &* 131) &+ Int($1) }
        for _ in 0..<58 {
            n = (n &* 1103515245 &+ 12345) & 0x7fffffff
            widths.append((n % 4) + 1)
        }
        return widths
    }
}
