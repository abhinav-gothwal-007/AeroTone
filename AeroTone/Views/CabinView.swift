import SwiftUI

/// Full-cabin view for the menu bar popover. The fuselage silhouette is part of the
/// scrolling content (sized to the whole cabin), so the nose, body, and tail scroll
/// together as one plane — a wider 2-2 cabin up front, a standard 3-3 cabin in back.
struct CabinView: View {
    let layout: CabinLayout
    let seats: [Seat]
    let selected: Seat?
    let onSelect: (Seat) -> Void

    private var lookup: [String: Seat] {
        Dictionary(uniqueKeysWithValues: seats.map { ($0.id, $0) })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                cockpit
                ForEach(layout.sections) { section in
                    sectionView(section)
                }
                tail
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(fuselage)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.never)
    }

    // MARK: - Fuselage (scrolls with the seats)

    private var fuselage: some View {
        FuselageShape()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.10),
                        Color.white.opacity(0.04),
                        Color.black.opacity(0.16)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                FuselageShape()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.45), .white.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 14, y: 8)
    }

    // MARK: - Cockpit / tail caps

    private var cockpit: some View {
        VStack(spacing: 5) {
            Windshield()
                .fill(.white.opacity(0.14))
                .overlay(Windshield().stroke(.white.opacity(0.3), lineWidth: 0.6))
                .frame(width: 40, height: 18)
            Text("FLIGHT DECK")
                .font(.system(size: 7, weight: .bold, design: .rounded))
                .kerning(1.4)
                .foregroundStyle(.white.opacity(0.32))
        }
        .frame(height: 46)
        .padding(.top, 6)
    }

    private var tail: some View {
        VStack(spacing: 4) {
            Text("GALLEY · AFT")
                .font(.system(size: 7, weight: .bold, design: .rounded))
                .kerning(1.4)
                .foregroundStyle(.white.opacity(0.3))
            Triangle()
                .fill(.white.opacity(0.12))
                .overlay(Triangle().stroke(.white.opacity(0.22), lineWidth: 0.5))
                .frame(width: 16, height: 18)
        }
        .frame(height: 50)
        .padding(.bottom, 8)
    }

    // MARK: - Sections

    private func sectionView(_ section: CabinSection) -> some View {
        let isFront = section.seatClass == .business
        return VStack(spacing: 6) {
            zoneDivider(
                label: isFront ? "Forward · 2-2" : "Main · 3-3",
                accent: seatClassColor(section.seatClass)
            )
            ForEach(section.rows, id: \.self) { row in
                rowView(section: section, row: row, isFront: isFront)
            }
        }
    }

    private func zoneDivider(label: String, accent: Color) -> some View {
        HStack(spacing: 8) {
            Capsule().fill(accent.opacity(0.4)).frame(height: 1)
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .kerning(1.2)
                .foregroundStyle(accent.opacity(0.9))
                .fixedSize()
            Capsule().fill(accent.opacity(0.4)).frame(height: 1)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }

    private func rowView(section: CabinSection, row: Int, isFront: Bool) -> some View {
        let seatW: CGFloat = isFront ? 38 : 28
        let seatSpacing: CGFloat = isFront ? 6 : 4
        return HStack(spacing: 6) {
            rowNumber(row)
            HStack(spacing: seatSpacing) {
                ForEach(Array(section.columns.enumerated()), id: \.offset) { _, col in
                    if col.isEmpty {
                        Color.clear.frame(width: isFront ? 22 : 16, height: 28)
                    } else if let seat = lookup["\(row)\(col)"] {
                        SeatTile(
                            seat: seat,
                            isSelected: selected?.id == seat.id,
                            width: seatW,
                            onTap: { onSelect(seat) }
                        )
                    } else {
                        Color.clear.frame(width: seatW, height: 28)
                    }
                }
            }
            rowNumber(row)
        }
    }

    private func rowNumber(_ row: Int) -> some View {
        Text("\(row)")
            .font(.system(size: 8, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.3))
            .frame(width: 16)
    }
}

private struct SeatTile: View {
    let seat: Seat
    let isSelected: Bool
    let width: CGFloat
    let onTap: () -> Void

    @State private var hover = false

    var body: some View {
        let accent = seatClassColor(seat.seatClass)
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(fill(accent))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(border(accent), lineWidth: isSelected ? 1.5 : 0.6)
                )

            if seat.isAvailable {
                Capsule()
                    .fill(isSelected ? accent.opacity(0.85) : accent.opacity(0.4))
                    .frame(width: width * 0.55, height: 3)
                    .offset(y: -8)
            }

            if isSelected {
                Image(systemName: "person.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(accent)
                    .transition(.scale.combined(with: .opacity))
            } else if !seat.isAvailable {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.25))
            }
        }
        .frame(width: width, height: 28)
        .shadow(color: isSelected ? accent.opacity(0.7) : .clear, radius: 8)
        .scaleEffect(isSelected ? 1.14 : (hover && seat.isAvailable ? 1.07 : 1.0))
        .animation(.spring(response: 0.32, dampingFraction: 0.68), value: isSelected)
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: hover)
        .contentShape(RoundedRectangle(cornerRadius: 7))
        .onTapGesture {
            guard seat.isAvailable else { return }
            onTap()
        }
        .onHover { hover = $0 }
        .help(seat.isAvailable ? "Seat \(seat.label)" : "Seat \(seat.label) — taken")
    }

    private func fill(_ accent: Color) -> Color {
        if !seat.isAvailable { return .white.opacity(0.06) }
        if isSelected { return .white }
        if hover { return accent.opacity(0.42) }
        return accent.opacity(0.18)
    }

    private func border(_ accent: Color) -> Color {
        if !seat.isAvailable { return .white.opacity(0.12) }
        if isSelected { return accent }
        return accent.opacity(0.45)
    }
}

// MARK: - Shapes

/// Top-down airliner silhouette: rounded nose at the top, straight body, tapered tail.
private struct FuselageShape: Shape {
    var noseHeight: CGFloat = 54
    var tailHeight: CGFloat = 70

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let midX = rect.midX
        let bodyTop = rect.minY + noseHeight
        let bodyBottom = rect.maxY - tailHeight

        // Nose tip
        p.move(to: CGPoint(x: midX, y: rect.minY))
        // Right nose shoulder (rounded dome)
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: bodyTop),
            control: CGPoint(x: rect.maxX, y: rect.minY + noseHeight * 0.5)
        )
        // Right body
        p.addLine(to: CGPoint(x: rect.maxX, y: bodyBottom))
        // Right tail taper to bottom center
        p.addQuadCurve(
            to: CGPoint(x: midX, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY - tailHeight * 0.32)
        )
        // Left tail taper back up
        p.addQuadCurve(
            to: CGPoint(x: rect.minX, y: bodyBottom),
            control: CGPoint(x: rect.minX, y: rect.maxY - tailHeight * 0.32)
        )
        // Left body
        p.addLine(to: CGPoint(x: rect.minX, y: bodyTop))
        // Left nose shoulder
        p.addQuadCurve(
            to: CGPoint(x: midX, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY + noseHeight * 0.5)
        )
        p.closeSubpath()
        return p
    }
}

/// Cockpit windshield: a small trapezoid wider at the bottom.
private struct Windshield: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let inset = rect.width * 0.22
        p.move(to: CGPoint(x: rect.minX + inset, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
