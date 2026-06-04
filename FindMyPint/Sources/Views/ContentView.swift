import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PlaceViewModel()
    @ObservedObject var locationManager = LocationManager.shared

    var body: some View {
        ZStack(alignment: .top) {
            TabView {
                CompassView(viewModel: viewModel)
                    .tabItem {
                        Label("Nearest", systemImage: "scope")
                    }

                PlaceMapView(viewModel: viewModel)
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
            }
            .onAppear {
                viewModel.startLocationUpdates()
            }

            FilterBar(viewModel: viewModel)
        }
    }
}
