import SwiftUI

struct ContentView: View {
    @Bindable var router: AppRouter

    var body: some View {
        ZStack {
            SkyBackground(progress: skyProgress, phase: skyPhase)

            page
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(router.currentPage)
                .transition(transition)
        }
        .preferredColorScheme(.dark)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var page: some View {
        switch router.currentPage {
        case .welcome:
            WelcomePage(router: router)
        case .homeAirport:
            HomeAirportPage(router: router)
        case .destination:
            DestinationPage(router: router)
        case .seat:
            SeatSelectionPage(router: router)
        case .boarding:
            BoardingPassPage(router: router)
        case .flight:
            FlightPage(router: router)
        }
    }

    private var transition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    private var skyProgress: Double {
        switch router.currentPage {
        case .welcome, .homeAirport: return 0.10
        case .destination: return 0.30
        case .seat: return 0.42
        case .boarding: return 0.55
        case .flight: return 0.65
        }
    }

    private var skyPhase: FlightPhase {
        switch router.currentPage {
        case .welcome, .homeAirport, .destination, .seat: return .boarding
        case .boarding: return .takeoff
        case .flight: return .cruise
        }
    }
}
