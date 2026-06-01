import SwiftUI

struct WelcomePage: View {
    @Bindable var router: AppRouter
    @State private var appear = false

    /// Dark ink used for the logo and titles so they read against the bright dawn sky.
    private static let inkColor = Color.flowInk

    /// Shared blue tint for the primary action buttons.
    private static let buttonTint = Color(red: 0.30, green: 0.52, blue: 0.92)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 10) {
                Image("InAppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .colorInvert()
                    .shadow(color: .white.opacity(0.4), radius: 10)
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                .scaleEffect(appear ? 1 : 0.6)
                .opacity(appear ? 1 : 0)

                Text("AeroTone")
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundStyle(Self.inkColor)
                    .shadow(color: .white.opacity(0.35), radius: 8, y: 1)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 16)

                Text("Focus, in flight.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Self.inkColor.opacity(0.7))
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 16)
            }

            Spacer().frame(height: 26)

            VStack(spacing: 10) {
                actionRow(
                    title: "Begin a Flight",
                    subtitle: "Pick a destination and start focusing",
                    systemImage: "airplane.departure",
                    prominent: true,
                    tint: Self.buttonTint
                ) {
                    router.go(to: .destination)
                }

                actionRow(
                    title: "Home Airport",
                    subtitle: "\(router.homeAirport.code) · \(router.homeAirport.city)",
                    systemImage: "house.fill",
                    prominent: true,
                    tint: Self.buttonTint
                ) {
                    router.go(to: .homeAirport)
                }

                if router.hasActiveFlight {
                    actionRow(
                        title: "Resume Flight",
                        subtitle: router.flightPlan.map { "\($0.route.origin.code) → \($0.route.destination.code)" } ?? "In progress",
                        systemImage: "play.fill",
                        prominent: true,
                        tint: Color(red: 0.55, green: 0.95, blue: 0.7)
                    ) {
                        router.go(to: .flight)
                    }
                }
            }
            .padding(.horizontal, 20)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "person.fill")
                    .font(.system(size: 9, weight: .semibold))
                Text("Welcome, \(router.passengerName.capitalized)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
            .foregroundStyle(Self.inkColor)
            .padding(.bottom, 18)
            .opacity(appear ? 1 : 0)
        }
        .padding(.top, 18)
        .onAppear {
            withAnimation(.spring(response: 0.85, dampingFraction: 0.75).delay(0.05)) {
                appear = true
            }
        }
    }

    private func actionRow(
        title: String,
        subtitle: String,
        systemImage: String,
        prominent: Bool,
        tint: Color = .white,
        action: @escaping () -> Void
    ) -> some View {
        WelcomeActionButton(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            prominent: prominent,
            tint: tint,
            action: action
        )
    }
}

private struct WelcomeActionButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let prominent: Bool
    let tint: Color
    let action: () -> Void

    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(prominent ? tint.opacity(0.25) : .white.opacity(0.10))
                        .frame(width: 34, height: 34)
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(hover ? 0.85 : 0.5))
                    .offset(x: hover ? 3 : 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(WelcomeActionStyle(prominent: prominent, tint: tint, hover: hover))
        .onHover { isHovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                hover = isHovering
            }
        }
    }
}

private struct WelcomeActionStyle: ButtonStyle {
    let prominent: Bool
    let tint: Color
    var hover: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
                if #available(macOS 26.0, *) {
                    ZStack {
                        shape.fill(.clear).glassEffect(in: shape)
                        if prominent {
                            // Solid (non-additive) colored fill so the button reads as a
                            // saturated panel on any sky, instead of blowing out to white.
                            shape.fill(
                                LinearGradient(
                                    colors: [tint.opacity(0.62), tint.opacity(0.40)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        } else {
                            shape.fill(.black.opacity(0.14))
                        }
                    }
                } else {
                    ZStack {
                        shape.fill(.ultraThinMaterial)
                        if prominent {
                            shape.fill(tint.opacity(0.5))
                        } else {
                            shape.fill(.black.opacity(0.16))
                        }
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.55), .white.opacity(0.08), .white.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.7
                    )
                    .blendMode(.plusLighter)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(hover ? 0.22 : 0.15), radius: hover ? 14 : 8, y: hover ? 8 : 5)
            .shadow(color: tint.opacity(prominent && hover ? 0.45 : 0), radius: 16)
            .scaleEffect(configuration.isPressed ? 0.97 : (hover ? 1.02 : 1.0))
            .offset(y: configuration.isPressed ? 0 : (hover ? -2 : 0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hover)
    }
}
