import SwiftUI
import MapKit

struct PlaceMapView: View {
    @ObservedObject var viewModel: PlaceViewModel
    @ObservedObject var locationManager = LocationManager.shared
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                ForEach(viewModel.filteredPlaces) { place in
                    Annotation(place.name, coordinate: place.coordinate) {
                        Circle()
                            .fill(tintColor(for: place))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            )
                            .onTapGesture {
                                viewModel.selectPlace(place)
                            }
                    }
                }

                if let userLocation = locationManager.location {
                    Annotation("You", coordinate: userLocation.coordinate) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 3)
                            )
                    }
                }
            }
            .mapStyle(.standard)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }

            VStack {
                Spacer()
                if let selected = viewModel.selectedPlace ?? viewModel.nearestPlace {
                    PlaceCardView(place: selected)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3), value: viewModel.selectedPlace?.id)
        }
        .onAppear {
            if let userLocation = locationManager.location {
                cameraPosition = .region(MKCoordinateRegion(
                    center: userLocation.coordinate,
                    latitudinalMeters: 2000,
                    longitudinalMeters: 2000
                ))
            }
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if let location = newLocation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    latitudinalMeters: 2000,
                    longitudinalMeters: 2000
                ))
            }
        }
    }

    private func tintColor(for place: Place) -> Color {
        if place.id == viewModel.nearestPlace?.id {
            return .green
        }
        return .blue
    }
}

struct PlaceCardView: View {
    let place: Place

    private func formatDistance(_ meters: CLLocationDistance) -> String {
        if meters < 1000 {
            return String(format: "%.0fm", meters)
        } else {
            return String(format: "%.1fkm", meters / 1000)
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            Text(place.category.icon)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Text(place.category.rawValue)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                HStack {
                    Label(formatDistance(place.distance), systemImage: "location.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.blue)

                    if let hours = place.hours {
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(hours)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            if let isOpen = place.isOpen {
                Text(isOpen ? "Open" : "Closed")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isOpen ? .green : .red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(isOpen ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
}