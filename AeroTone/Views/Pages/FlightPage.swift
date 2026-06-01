import SwiftUI

struct FlightPage: View {
    @Bindable var router: AppRouter
    @State private var showArrival = false
    @State private var showMixer = false

    var body: some View {
        Group {
            if let plan = router.flightPlan, let controller = router.flightController {
                VStack(spacing: 10) {
                    topBar(plan: plan, controller: controller)

                    GlobeView(route: plan.route, progress: controller.progress)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .glassPanel(cornerRadius: 18, elevation: 1.0)

                    timerStrip(controller: controller)

                    ControlBar(
                        controller: controller,
                        onEnd: { router.reset() },
                        soundActive: router.ambience.isActive,
                        onToggleSound: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showMixer.toggle()
                            }
                        }
                    )
                }
                .padding(.horizontal, 14)
                .padding(.top, 26)
                .padding(.bottom, 14)
                .overlay(alignment: .bottom) {
                    if showMixer {
                        ZStack(alignment: .bottom) {
                            Color.black.opacity(0.35)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        showMixer = false
                                    }
                                }
                            AmbienceMixerPanel(mixer: router.ambience) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showMixer = false
                                }
                            }
                            .padding(.bottom, 12)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .onAppear {
                    router.ambience.prepare()
                    if controller.elapsed == 0 && !controller.isRunning && !controller.didComplete {
                        controller.startFlight()
                    }
                }
                .overlay {
                    if showArrival {
                        ArrivalCelebration(plan: plan) {
                            router.reset()
                        }
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .onChange(of: controller.didComplete) { _, completed in
                    if completed {
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
                            showArrival = true
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
    }

    private func topBar(plan: FlightPlan, controller: FlightController) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(plan.route.origin.code)
                    Image(systemName: "airplane")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(plan.route.destination.code)
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Text(plan.flightNumber).monospaced()
                    Text("·")
                    Text(plan.seat.label)
                    Text("·")
                    Text(plan.gate)
                }
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            phaseChip(controller: controller)
        }
        .padding(10)
        .glassPanel(cornerRadius: 14, elevation: 0.7)
    }

    private func phaseChip(controller: FlightController) -> some View {
        HStack(spacing: 5) {
            Image(systemName: controller.currentPhase.systemImage)
                .font(.system(size: 9, weight: .semibold))
            Text(controller.currentPhase.label.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .kerning(1.4)
        }
        .foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(.white.opacity(0.12)))
        .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 0.5))
    }

    private func timerStrip(controller: FlightController) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 1) {
                Text("REMAINING")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .kerning(1.4)
                    .foregroundStyle(.white.opacity(0.5))
                Text(formatTime(controller.remaining))
                    .font(.system(size: 26, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }

            Spacer()

            VStack(alignment: .leading, spacing: 3) {
                Text("PROGRESS")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .kerning(1.4)
                    .foregroundStyle(.white.opacity(0.5))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.1))
                            .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 0.5))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.55, green: 0.95, blue: 0.8),
                                        Color(red: 0.5, green: 0.85, blue: 1.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(6, geo.size.width * controller.progress))
                            .shadow(color: Color(red: 0.5, green: 0.9, blue: 0.9).opacity(0.55), radius: 6)
                    }
                }
                .frame(height: 7)
            }
            .frame(maxWidth: 130)

            VStack(alignment: .trailing, spacing: 1) {
                Text("ETA")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .kerning(1.4)
                    .foregroundStyle(.white.opacity(0.5))
                Text(Date().addingTimeInterval(controller.remaining), format: .dateTime.hour().minute())
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassPanel(cornerRadius: 14, elevation: 0.7)
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

struct ArrivalCelebration: View {
    let plan: FlightPlan
    let onDismiss: () -> Void
    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.55, green: 0.95, blue: 0.75).opacity(0.6),
                                    Color(red: 0.4, green: 0.85, blue: 0.95).opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .blur(radius: 14)

                    Image(systemName: "airplane.arrival")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: appear)
                }

                VStack(spacing: 4) {
                    Text("Welcome to \(plan.route.destination.city)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text("\(plan.route.origin.code) → \(plan.route.destination.code)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(Int(plan.duration / 60)) focused minutes")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }

                Button(action: onDismiss) {
                    Text("Take another flight")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                }
                .buttonStyle(PrimaryPillStyle())
                .padding(.top, 4)
            }
            .padding(24)
            .frame(width: 300)
            .glassPanel(cornerRadius: 24, elevation: 1.6)
            .scaleEffect(appear ? 1 : 0.9)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                appear = true
            }
        }
    }
}
