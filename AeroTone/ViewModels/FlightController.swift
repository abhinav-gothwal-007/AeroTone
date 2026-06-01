import SwiftUI
import Combine
import Observation

@MainActor
@Observable
final class FlightController {
    let plan: FlightPlan

    var phase: FlightPhase = .boarding
    var isRunning: Bool = false
    var elapsed: TimeInterval = 0
    var didComplete: Bool = false

    private var ticker: AnyCancellable?
    private var startTimestamp: Date?
    private var accumulatedBeforePause: TimeInterval = 0

    init(plan: FlightPlan) {
        self.plan = plan
    }

    var duration: TimeInterval { plan.duration }

    var remaining: TimeInterval {
        max(0, duration - elapsed)
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1, max(0, elapsed / duration))
    }

    var currentPhase: FlightPhase {
        if !isRunning && elapsed == 0 { return .boarding }
        if elapsed >= duration { return .arrived }
        let p = progress
        if p < 0.1 { return .takeoff }
        if p > 0.9 { return .landing }
        return .cruise
    }

    func startFlight() {
        if didComplete { return }
        startTimestamp = Date()
        isRunning = true
        phase = currentPhase
        startTicker()
    }

    func pauseFlight() {
        guard isRunning else { return }
        if let started = startTimestamp {
            accumulatedBeforePause += Date().timeIntervalSince(started)
        }
        startTimestamp = nil
        isRunning = false
        ticker?.cancel()
    }

    func resumeFlight() {
        startTimestamp = Date()
        isRunning = true
        startTicker()
    }

    func endFlight() {
        ticker?.cancel()
        isRunning = false
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard isRunning, let started = startTimestamp else { return }
        let live = Date().timeIntervalSince(started)
        elapsed = min(duration, accumulatedBeforePause + live)
        phase = currentPhase

        if elapsed >= duration {
            isRunning = false
            ticker?.cancel()
            didComplete = true
        }
    }
}
