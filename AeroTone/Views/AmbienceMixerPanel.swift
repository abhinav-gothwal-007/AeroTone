import SwiftUI

/// Compact in-flight sound mixer: a master toggle/volume plus an independent
/// slider for each ambient layer, presented as a glass panel over the flight page.
struct AmbienceMixerPanel: View {
    @Bindable var mixer: AmbienceMixer
    let onClose: () -> Void

    private let engineTint = Color(red: 0.7, green: 0.55, blue: 1.0)
    private let noiseTint = Color(red: 0.5, green: 0.85, blue: 1.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            masterRow

            Divider().overlay(Color.white.opacity(0.12))

            sliderRow(icon: "airplane", label: "Engine", tint: engineTint, value: $mixer.engineGain)

            VStack(alignment: .leading, spacing: 8) {
                sliderRow(icon: "waveform", label: "Noise", tint: noiseTint, value: $mixer.noiseGain)
                noiseColorPicker
            }
        }
        .padding(16)
        .frame(width: 320)
        .glassPanel(cornerRadius: 22, elevation: 1.6)
    }

    private var header: some View {
        HStack {
            Text("Cabin Sound")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(.white.opacity(0.1)))
            }
            .buttonStyle(.plain)
        }
    }

    private var masterRow: some View {
        HStack(spacing: 10) {
            Image(systemName: mixer.isActive ? "speaker.wave.3.fill" : "speaker.slash.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 24)
            Text("Master")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Slider(value: $mixer.masterVolume, in: 0...1)
                .controlSize(.small)
                .tint(.white)
                .disabled(!mixer.isActive)
                .opacity(mixer.isActive ? 1 : 0.4)
            Toggle("", isOn: Binding(
                get: { mixer.isActive },
                set: { $0 ? mixer.start() : mixer.stop() }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.mini)
        }
    }

    private var noiseColorPicker: some View {
        HStack(spacing: 6) {
            ForEach(NoiseColor.allCases) { color in
                let selected = mixer.noiseColor == color
                Button {
                    mixer.noiseColor = color
                } label: {
                    Text(color.label)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(selected ? .black.opacity(0.85) : .white.opacity(0.7))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(selected ? noiseTint.opacity(0.9) : .white.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 34)
    }

    private func sliderRow(icon: String, label: String, tint: Color, value: Binding<Float>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Slider(value: value, in: 0...1)
                    .controlSize(.small)
                    .tint(tint)
            }
        }
        .opacity(mixer.isActive ? 1 : 0.5)
        .disabled(!mixer.isActive)
    }
}
