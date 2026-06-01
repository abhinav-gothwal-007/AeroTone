import SwiftUI

struct ControlBar: View {
    @Bindable var controller: FlightController
    let onEnd: () -> Void
    var soundActive: Bool = false
    var onToggleSound: () -> Void = {}

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggleSound) {
                Image(systemName: soundActive ? "speaker.wave.2.fill" : "speaker.slash.fill")
            }
            .buttonStyle(LiquidGlassButtonStyle(prominent: false, size: 38))
            .help("Cabin sound")

            Spacer()

            if controller.isRunning {
                Button {
                    controller.pauseFlight()
                } label: {
                    Image(systemName: "pause.fill")
                }
                .buttonStyle(LiquidGlassButtonStyle(prominent: false, size: 38))
                .help("Pause flight")
            } else if controller.elapsed > 0 && !controller.didComplete {
                Button {
                    controller.resumeFlight()
                } label: {
                    Image(systemName: "play.fill")
                        .offset(x: 1)
                }
                .buttonStyle(LiquidGlassButtonStyle(prominent: true, tint: .white, size: 44))
                .help("Resume flight")
            }

            Button {
                controller.endFlight()
                onEnd()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                    Text("End")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(PillBorderlessStyle())

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassPanel(cornerRadius: 26, elevation: 0.8)
    }
}

private struct PillBorderlessStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Capsule(style: .continuous).fill(.white.opacity(0.1))
            )
            .overlay(
                Capsule(style: .continuous).stroke(.white.opacity(0.18), lineWidth: 0.5)
            )
            .clipShape(Capsule(style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
