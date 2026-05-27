import Foundation
import CoreLocation
import MapKit
import Combine

@MainActor
final class PlaceViewModel: ObservableObject {
    @Published var places: [Place] = []
    @Published var nearestPlace: Place?
    @Published var selectedPlace: Place?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let locationManager = LocationManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupLocationObserver()
    }

    private func setupLocationObserver() {
        locationManager.$location
            .compactMap { $0 }
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] location in
                Task { await self?.searchNearbyPlaces(userLocation: location) }
            }
            .store(in: &cancellables)
    }

    func searchNearbyPlaces(userLocation: CLLocation) async {
        isLoading = true
        errorMessage = nil

        let searchTerms = ["pub", "bar", "brewery", "off licence", "liquor store", "beer shop"]
        var allPlaces: [Place] = []

        await withTaskGroup(of: [Place].self) { group in
            for term in searchTerms {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = term
                request.region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    latitudinalMeters: 5000,
                    longitudinalMeters: 5000
                )
                request.resultTypes = .pointOfInterest

                group.addTask {
                    do {
                        let search = MKLocalSearch(request: request)
                        let response = try await search.start()
                        return response.mapItems.map { Place(from: $0, userLocation: userLocation) }
                    } catch {
                        return []
                    }
                }
            }

            for await result in group {
                allPlaces.append(contentsOf: result)
            }
        }

        let uniquePlaces = Dictionary(grouping: allPlaces, by: { $0.id })
            .compactMap { $0.value.first }
            .sorted { $0.distance < $1.distance }

        places = uniquePlaces
        nearestPlace = uniquePlaces.first
        isLoading = false
    }

    func requestLocationPermission() {
        locationManager.requestPermission()
    }

    func startLocationUpdates() {
        locationManager.startUpdating()
    }

    func selectPlace(_ place: Place) {
        selectedPlace = place
    }
}