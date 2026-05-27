import Foundation
import CoreLocation
import MapKit
import Combine

@MainActor
final class PlaceViewModel: ObservableObject {
    @Published var places: [Place] = []
    @Published var filteredPlaces: [Place] = []
    @Published var nearestPlace: Place?
    @Published var selectedPlace: Place?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var activeFilters: Set<PlaceCategory> = Set(PlaceCategory.allCases)

    private let locationManager = LocationManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var pendingAllPlaces: [Place] = []

    init() {
        setupLocationObserver()
        setupFilterObserver()
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

    private func setupFilterObserver() {
        $activeFilters
            .sink { [weak self] filters in
                self?.applyFilters(filters)
            }
            .store(in: &cancellables)
    }

    private func applyFilters(_ filters: Set<PlaceCategory>) {
        filteredPlaces = places.filter { filters.contains($0.category) }
        nearestPlace = filteredPlaces.first
    }

    func toggleFilter(_ category: PlaceCategory) {
        if activeFilters.contains(category) {
            activeFilters.remove(category)
        } else {
            activeFilters.insert(category)
        }
    }

    func setAllFilters(_ enabled: Bool) {
        if enabled {
            activeFilters = Set(PlaceCategory.allCases)
        } else {
            activeFilters = []
        }
    }

    func searchNearbyPlaces(userLocation: CLLocation) async {
        // Set loading but keep existing places visible
        isLoading = true
        errorMessage = nil

        var newPlaces: [Place] = []

        await withTaskGroup(of: [Place].self) { group in
            for category in PlaceCategory.allCases {
                for term in category.searchTerms {
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
            }

            for await result in group {
                newPlaces.append(contentsOf: result)
            }
        }

        // Deduplicate and sort
        let uniquePlaces = Dictionary(grouping: newPlaces, by: { $0.id })
            .compactMap { $0.value.first }
            .sorted { $0.distance < $1.distance }

        // Store pending - don't update display yet
        pendingAllPlaces = uniquePlaces

        // Only update display and recompute filtered/nearest when we have results
        // This prevents the momentary blank state
        if !pendingAllPlaces.isEmpty {
            places = pendingAllPlaces
            applyFilters(activeFilters)
        }

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
