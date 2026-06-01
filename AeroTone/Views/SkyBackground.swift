import SwiftUI

struct SkyBackground: View {
    let progress: Double
    let phase: FlightPhase

    @State private var drift: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: skyColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [horizonGlow.opacity(0.6), .clear],
                center: .init(x: 0.5, y: 0.85),
                startRadius: 40,
                endRadius: 700
            )
            .ignoresSafeArea()
            .blendMode(.plusLighter)

            StarField(opacity: starOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            CloudLayer(drift: drift, depth: 1.0, opacity: cloudOpacity * 0.55, hue: cloudHue, seed: 0)
                .offset(y: 60)
                .allowsHitTesting(false)

            CloudLayer(drift: drift * 0.6, depth: 1.6, opacity: cloudOpacity, hue: cloudHue, seed: 17)
                .offset(y: 150)
                .allowsHitTesting(false)

            CloudLayer(drift: drift * 0.35, depth: 2.4, opacity: cloudOpacity * 0.7, hue: cloudHue, seed: 31)
                .offset(y: 260)
                .allowsHitTesting(false)

            CelestialBody(progress: progress)
                .allowsHitTesting(false)
        }
        .animation(.easeInOut(duration: 1.5), value: phase)
        .onAppear {
            withAnimation(.linear(duration: 360).repeatForever(autoreverses: false)) {
                drift = 1
            }
        }
    }

    private var skyColors: [Color] {
        // Cycle: dawn → day → dusk → night, mapped to flight progress
        let stops: [(Double, [Color])] = [
            (0.0, [Color(red: 0.95, green: 0.72, blue: 0.55), Color(red: 0.65, green: 0.55, blue: 0.75), Color(red: 0.35, green: 0.40, blue: 0.62)]), // dawn
            (0.25, [Color(red: 0.45, green: 0.72, blue: 0.95), Color(red: 0.30, green: 0.55, blue: 0.85), Color(red: 0.20, green: 0.40, blue: 0.70)]), // morning
            (0.5, [Color(red: 0.30, green: 0.60, blue: 0.95), Color(red: 0.20, green: 0.45, blue: 0.85), Color(red: 0.12, green: 0.30, blue: 0.60)]), // day
            (0.75, [Color(red: 0.92, green: 0.50, blue: 0.45), Color(red: 0.55, green: 0.35, blue: 0.65), Color(red: 0.18, green: 0.20, blue: 0.45)]), // dusk
            (1.0, [Color(red: 0.10, green: 0.10, blue: 0.30), Color(red: 0.05, green: 0.05, blue: 0.18), Color(red: 0.02, green: 0.02, blue: 0.08)])  // night
        ]
        return interpolate(stops: stops, at: progress)
    }

    private var horizonGlow: Color {
        if progress < 0.25 {
            return Color(red: 1.0, green: 0.75, blue: 0.55)
        } else if progress < 0.55 {
            return Color(red: 0.75, green: 0.90, blue: 1.0)
        } else if progress < 0.85 {
            return Color(red: 1.0, green: 0.55, blue: 0.45)
        } else {
            return Color(red: 0.35, green: 0.30, blue: 0.55)
        }
    }

    private var cloudHue: Color {
        if progress < 0.55 {
            return Color.white
        } else if progress < 0.85 {
            return Color(red: 1.0, green: 0.85, blue: 0.75)
        } else {
            return Color(red: 0.55, green: 0.55, blue: 0.75)
        }
    }

    private var cloudOpacity: Double {
        if progress > 0.85 { return 0.25 }
        return 0.55
    }

    private var starOpacity: Double {
        if progress < 0.7 { return 0 }
        return min(1, (progress - 0.7) / 0.25)
    }

    private func interpolate(stops: [(Double, [Color])], at value: Double) -> [Color] {
        let clamped = max(0, min(1, value))
        guard stops.count > 1 else { return stops.first?.1 ?? [.blue] }
        for i in 0..<(stops.count - 1) {
            let a = stops[i], b = stops[i + 1]
            if clamped >= a.0 && clamped <= b.0 {
                let t = (clamped - a.0) / max(0.0001, b.0 - a.0)
                return zip(a.1, b.1).map { lerp($0, $1, t: t) }
            }
        }
        return stops.last?.1 ?? [.blue]
    }

    private func lerp(_ a: Color, _ b: Color, t: Double) -> Color {
        let ar = a.rgba, br = b.rgba
        return Color(
            red: ar.r + (br.r - ar.r) * t,
            green: ar.g + (br.g - ar.g) * t,
            blue: ar.b + (br.b - ar.b) * t,
            opacity: ar.a + (br.a - ar.a) * t
        )
    }
}

private extension Color {
    var rgba: (r: Double, g: Double, b: Double, a: Double) {
        #if canImport(AppKit)
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        return (Double(ns.redComponent), Double(ns.greenComponent), Double(ns.blueComponent), Double(ns.alphaComponent))
        #else
        return (0, 0, 0, 1)
        #endif
    }
}

private struct CloudLayer: View {
    let drift: CGFloat
    let depth: Double
    let opacity: Double
    let hue: Color
    let seed: Int

    private struct Cloud: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
    }

    private var clouds: [Cloud] {
        (0..<7).map { i in
            let s = (i + seed) * 37
            let x = CGFloat((s % 100)) / 100
            let y = CGFloat(((s * 13) % 40)) - 20
            let w = 120 + CGFloat(((s * 7) % 100))
            return Cloud(x: x, y: y, width: w / CGFloat(depth))
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(clouds) { cloud in
                    let totalWidth = geo.size.width + cloud.width * 2
                    let baseX = cloud.x * geo.size.width
                    let translated = (baseX - drift * totalWidth).truncatingRemainder(dividingBy: totalWidth)
                    let x = translated < -cloud.width ? translated + totalWidth : translated
                    Capsule()
                        .fill(hue.opacity(opacity / depth))
                        .frame(width: cloud.width, height: cloud.width * 0.32 / CGFloat(depth))
                        .position(x: x, y: cloud.y + geo.size.height / 2)
                }
            }
        }
        .frame(height: 80)
        .compositingGroup()
        .blur(radius: depth < 1.5 ? 6 : 2)
        .opacity(0.85)
    }
}

private struct StarField: View {
    let opacity: Double

    private static let stars: [(CGPoint, Double)] = (0..<120).map { i in
        let x = Double((i * 89) % 1000) / 1000.0
        let y = Double((i * 53) % 600) / 1000.0
        let size = Double((i * 17) % 5) / 5.0 * 1.6 + 0.5
        return (CGPoint(x: x, y: y), size)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<Self.stars.count, id: \.self) { i in
                    let star = Self.stars[i]
                    Circle()
                        .fill(.white.opacity(opacity * (0.4 + Double((i * 19) % 6) / 10.0)))
                        .frame(width: star.1, height: star.1)
                        .position(x: star.0.x * geo.size.width, y: star.0.y * geo.size.height)
                }
            }
        }
        .drawingGroup()
        .opacity(opacity > 0.05 ? 1 : 0)
    }
}

private struct CelestialBody: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let arcProgress = progress
            let x = arcProgress * geo.size.width
            let y = (1 - sin(arcProgress * .pi)) * geo.size.height * 0.55 + 40
            ZStack {
                Circle()
                    .fill(bodyGradient)
                    .frame(width: 90, height: 90)
                    .shadow(color: glowColor.opacity(0.6), radius: 40)
                    .shadow(color: glowColor.opacity(0.3), radius: 80)
                    .position(x: x, y: y)
            }
        }
    }

    private var bodyGradient: LinearGradient {
        if progress < 0.7 {
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.95, blue: 0.75), Color(red: 1.0, green: 0.8, blue: 0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color(red: 0.95, green: 0.95, blue: 0.98), Color(red: 0.75, green: 0.78, blue: 0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var glowColor: Color {
        if progress < 0.7 {
            return Color(red: 1.0, green: 0.8, blue: 0.4)
        } else {
            return Color(red: 0.75, green: 0.85, blue: 1.0)
        }
    }
}
