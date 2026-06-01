import SwiftUI

struct SeatSelectionPage: View {
    @Bindable var router: AppRouter

    @State private var seats: [Seat] = []
    @State private var picked: Seat?

    var body: some View {
        VStack(spacing: 12) {
            CompactHeader(title: "Choose your seat", subtitle: routeSummary, tint: .flowInk) {
                router.go(to: .destination)
            }

            CabinView(
                layout: .standard,
                seats: seats,
                selected: picked,
                onSelect: { seat in
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) {
                        picked = seat
                    }
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassPanel(cornerRadius: 18, elevation: 0.8)

            if let picked {
                selectedFooter(picked: picked)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            confirmButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 26)
        .padding(.bottom, 16)
        .onAppear {
            if seats.isEmpty, let route = router.route {
                seats = CabinLayout.standard.allSeats(seedFor: route)
            }
        }
    }

    private var routeSummary: String {
        guard let route = router.route else { return "" }
        return "\(route.origin.code) → \(route.destination.code) · \(formatDuration(route.duration))"
    }

    private func selectedFooter(picked: Seat) -> some View {
        HStack(spacing: 12) {
            Text(picked.label)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 56, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(seatClassColor(picked.seatClass).opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(seatClassColor(picked.seatClass).opacity(0.6), lineWidth: 0.7)
                        )
                )
            VStack(alignment: .leading, spacing: 1) {
                Text(picked.seatClass.label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(picked.seatClass.perk)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(10)
        .glassPanel(cornerRadius: 14, elevation: 0.6)
    }

    private var confirmButton: some View {
        Button {
            if let seat = picked { router.confirmSeat(seat) }
        } label: {
            HStack(spacing: 6) {
                Text(picked == nil ? "Pick a seat" : "Generate boarding pass")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                if picked != nil {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(PrimaryPillStyle())
        .disabled(picked == nil)
        .opacity(picked == nil ? 0.55 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: picked == nil)
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

func seatClassColor(_ seatClass: SeatClass) -> Color {
    switch seatClass {
    case .first:    return Color(red: 1.0, green: 0.75, blue: 0.3)
    case .business: return Color(red: 0.7, green: 0.55, blue: 1.0)
    case .premium:  return Color(red: 0.4, green: 0.85, blue: 0.95)
    case .economy:  return Color(red: 0.55, green: 0.95, blue: 0.7)
    }
}
