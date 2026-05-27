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
    @Environment(\.colorScheme) var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        ZStack {
            (isDark ? Color(hex: "1a1a1a") : Color(hex: "F5F0E6"))
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(isDark ? Color(hex: "ff3b30") : Color(hex: "c41e3a"))

                Text("Location Access Needed")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isDark ? .white : Color(hex: "222222"))

                Text("Find My Pint needs your location to show you the nearest pubs and beer shops.")
                    .font(.system(size: 16))
                    .foregroundColor(isDark ? .white.opacity(0.6) : Color(hex: "666666"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button(action: onRequest) {
                    Text("Enable Location")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isDark ? Color(hex: "ff3b30") : Color(hex: "c41e3a"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
            }
        }
    }
}

struct PermissionDeniedView: View {
    @Environment(\.colorScheme) var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        ZStack {
            (isDark ? Color(hex: "1a1a1a") : Color(hex: "F5F0E6"))
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 80))
                    .foregroundColor(isDark ? Color(hex: "ff3b30") : Color(hex: "c41e3a"))

                Text("Location Access Denied")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isDark ? .white : Color(hex: "222222"))

                Text("Please enable location access in Settings to use Find My Pint.")
                    .font(.system(size: 16))
                    .foregroundColor(isDark ? .white.opacity(0.6) : Color(hex: "666666"))
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
                        .background(isDark ? Color(hex: "ff3b30") : Color(hex: "c41e3a"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
            }
        }
    }
}
