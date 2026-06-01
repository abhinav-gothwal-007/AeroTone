import SwiftUI

@main
struct AeroToneApp: App {
    @State private var router = AppRouter()

    var body: some Scene {
        MenuBarExtra {
            ContentView(router: router)
                .frame(width: 400, height: 560)
        } label: {
            MenuBarLabel(router: router)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarLabel: View {
    @Bindable var router: AppRouter

    var body: some View {
        if let controller = router.flightController, controller.elapsed > 0, !controller.didComplete {
            HStack(spacing: 4) {
                Image(systemName: controller.isRunning ? "airplane" : "pause.fill")
                Text(format(controller.remaining))
                    .monospacedDigit()
            }
        } else {
            Image(systemName: "airplane")
        }
    }

    private func format(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d", h, m)
        }
        return String(format: "%d:%02d", m, s)
    }
}
