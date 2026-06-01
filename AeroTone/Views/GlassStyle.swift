import SwiftUI

extension Color {
    /// Dark ink for titles and text shown over bright, low-altitude skies (welcome, where-to, seat).
    static let flowInk = Color(red: 0.13, green: 0.16, blue: 0.30)
}

// MARK: - Glass styling helpers (Liquid Glass on macOS 26 with graceful fallback)

extension View {
    /// Applies a liquid glass panel look with rounded shape, subtle border highlight, and elevation.
    func glassPanel(
        cornerRadius: CGFloat = 28,
        tint: Color? = nil,
        elevation: Double = 1.0
    ) -> some View {
        modifier(GlassPanelModifier(cornerRadius: cornerRadius, tint: tint, elevation: elevation))
    }

    /// Soft inner-light edge highlight that gives panels their wet, liquid edge.
    func liquidEdge(cornerRadius: CGFloat = 28, intensity: Double = 1.0) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.55 * intensity),
                            .white.opacity(0.12 * intensity),
                            .white.opacity(0.05 * intensity),
                            .white.opacity(0.35 * intensity)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
                .blendMode(.plusLighter)
        )
    }
}

private struct GlassPanelModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color?
    let elevation: Double

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(macOS 26.0, *) {
            content
                .background {
                    shape
                        .fill(.clear)
                        .glassEffect(in: shape)
                }
                .overlay {
                    shape
                        .fill(tint?.opacity(0.18) ?? .clear)
                        .blendMode(.plusLighter)
                        .allowsHitTesting(false)
                }
                .overlay {
                    shape
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.55),
                                    .white.opacity(0.10),
                                    .white.opacity(0.04),
                                    .white.opacity(0.32)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                        .blendMode(.plusLighter)
                }
                .clipShape(shape)
                .shadow(color: .black.opacity(0.12 * elevation), radius: 12 * elevation, x: 0, y: 6 * elevation)
                .shadow(color: .black.opacity(0.08 * elevation), radius: 30 * elevation, x: 0, y: 18 * elevation)
        } else {
            content
                .background {
                    shape.fill(.ultraThinMaterial)
                }
                .overlay {
                    shape
                        .fill(tint?.opacity(0.18) ?? .clear)
                        .blendMode(.plusLighter)
                        .allowsHitTesting(false)
                }
                .overlay {
                    shape
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.05), .white.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                        .blendMode(.plusLighter)
                }
                .clipShape(shape)
                .shadow(color: .black.opacity(0.12 * elevation), radius: 12 * elevation, x: 0, y: 6 * elevation)
                .shadow(color: .black.opacity(0.08 * elevation), radius: 30 * elevation, x: 0, y: 18 * elevation)
        }
    }
}

// MARK: - Glass button styles

struct LiquidGlassButtonStyle: ButtonStyle {
    var prominent: Bool = false
    var tint: Color = .white
    var size: CGFloat = 54

    func makeBody(configuration: Configuration) -> some View {
        let shape = Circle()
        configuration.label
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .foregroundStyle(prominent ? Color.black.opacity(0.85) : Color.white)
            .frame(width: size, height: size)
            .background {
                if #available(macOS 26.0, *) {
                    ZStack {
                        shape.fill(prominent ? AnyShapeStyle(tint.opacity(0.95)) : AnyShapeStyle(Color.white.opacity(0.001)))
                        shape.fill(.clear).glassEffect(in: shape)
                    }
                } else {
                    if prominent {
                        shape.fill(tint.opacity(0.95))
                    } else {
                        shape.fill(.ultraThinMaterial)
                    }
                }
            }
            .overlay(
                shape.stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.7),
                            .white.opacity(0.08),
                            .white.opacity(0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
                .blendMode(.plusLighter)
            )
            .clipShape(shape)
            .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct PillGlassButtonStyle: ButtonStyle {
    var prominent: Bool = false
    var tint: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(prominent ? Color.black.opacity(0.85) : Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                let shape = Capsule(style: .continuous)
                if #available(macOS 26.0, *) {
                    ZStack {
                        shape.fill(prominent ? AnyShapeStyle(tint.opacity(0.95)) : AnyShapeStyle(Color.white.opacity(0.001)))
                        shape.fill(.clear).glassEffect(in: shape)
                    }
                } else {
                    if prominent {
                        shape.fill(tint.opacity(0.95))
                    } else {
                        shape.fill(.ultraThinMaterial)
                    }
                }
            }
            .overlay(
                Capsule(style: .continuous)
                    .stroke(.white.opacity(0.35), lineWidth: 0.7)
                    .blendMode(.plusLighter)
            )
            .clipShape(Capsule(style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
