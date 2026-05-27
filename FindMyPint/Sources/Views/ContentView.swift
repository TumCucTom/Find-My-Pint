import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PlaceViewModel()
    @ObservedObject var locationManager = LocationManager.shared

    var body: some View {
        Group {
            switch locationManager.authorizationStatus {
            case .notDetermined:
                PermissionRequestView {
                    viewModel.requestLocationPermission()
                }

            case .authorizedWhenInUse, .authorizedAlways:
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

                    // Filter bar at top
                    FilterBar(viewModel: viewModel)
                }

            case .denied, .restricted:
                PermissionDeniedView()

            @unknown default:
                PermissionRequestView {
                    viewModel.requestLocationPermission()
                }
            }
        }
    }
}

struct PermissionRequestView: View {
    let onRequest: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Location Access Needed")
                .font(.system(size: 24, weight: .semibold))

            Text("Find My Pint needs your location to show you the nearest pubs and beer shops.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onRequest) {
                Text("Enable Location")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)

            Text("Location Access Denied")
                .font(.system(size: 24, weight: .semibold))

            Text("Please enable location access in Settings to use Find My Pint.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}