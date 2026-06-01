import SwiftUI

struct BoardingPassPage: View {
    @Bindable var router: AppRouter

    @State private var printOffset: CGFloat = -440
    @State private var reveal: Double = 0
    @State private var showCta: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            CompactHeader(
                title: "Boarding pass",
                subtitle: router.flightPlan?.flightNumber
            ) {
                router.go(to: .seat)
            }

            VStack(spacing: 0) {
                printerSlot
                    .zIndex(2)

                if let plan = router.flightPlan {
                    BoardingPassView(plan: plan, revealProgress: reveal)
                        .offset(y: printOffset)
                        .rotationEffect(.degrees(printOffset > -20 ? sin(printOffset / 100) * 0.6 : 0))
                        .zIndex(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button {
                router.boardFlight()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 12, weight: .bold))
                    Text("Board Now")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(PrimaryPillStyle())
            .opacity(showCta ? 1 : 0.3)
            .scaleEffect(showCta ? 1 : 0.96)
            .disabled(!showCta)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showCta)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .onAppear { runPrintSequence() }
    }

    private var printerSlot: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.35),
                            Color.black.opacity(0.55)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 320, height: 18)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.5), radius: 6, y: 3)

            Capsule()
                .fill(.black.opacity(0.85))
                .frame(width: 288, height: 4)
                .overlay(
                    Capsule().stroke(.white.opacity(0.15), lineWidth: 0.4)
                )
        }
    }

    private func runPrintSequence() {
        printOffset = -440
        reveal = 0
        showCta = false

        withAnimation(.easeOut(duration: 1.4)) {
            printOffset = 0
        }
        withAnimation(.easeInOut(duration: 1.4).delay(0.15)) {
            reveal = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            showCta = true
        }
    }
}
