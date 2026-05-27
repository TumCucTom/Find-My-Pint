import Foundation
import MapKit
import CoreLocation

// MARK: - PlaceCategory

enum PlaceCategory: String, CaseIterable, Identifiable {
    case pub
    case bar
    case restaurant
    case offLicence
    case shop
    case unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pub: return "Pubs"
        case .bar: return "Bars"
        case .restaurant: return "Restaurants"
        case .offLicence: return "Off-Licences"
        case .shop: return "Shops"
        case .unknown: return "Other"
        }
    }

    init(from mapItem: MKMapItem) {
        guard let category = mapItem.pointOfInterestCategory else {
            self = .unknown
            return
        }

        let categoryString = String(describing: category)

        if categoryString.contains("pub") || categoryString.contains("brewery") || categoryString.contains("brewery") {
            self = .pub
        } else if categoryString.contains("bar") || categoryString.contains("nightclub") || categoryString.contains("nightLife") {
            self = .bar
        } else if categoryString.contains("restaurant") || categoryString.contains("food") {
            self = .restaurant
        } else if categoryString.contains("winery") || categoryString.contains("liquor") || categoryString.contains("wine") {
            self = .offLicence
        } else if categoryString.contains("shop") || categoryString.contains("store") || categoryString.contains("market") {
            self = .shop
        } else {
            self = .unknown
        }
    }

    var icon: String {
        switch self {
        case .pub: return "🍺"
        case .bar: return "🍸"
        case .restaurant: return "🍽️"
        case .offLicence: return "🍷"
        case .shop: return "🏪"
        case .unknown: return "📍"
        }
    }

    var searchTerms: [String] {
        switch self {
        case .pub: return ["pub", "brewery", "wetherspoons", "wetherspoon", "jd wetherspoon"]
        case .bar: return ["bar", "nightclub", "wine bar", "cocktail bar", "sports bar", "tavern"]
        case .restaurant: return ["restaurant", "cafe", "bistro", "eatery"]
        case .offLicence: return ["off licence", "off-licence", "liquor store", "wine shop", "beer shop"]
        case .shop: return ["convenience store", "supermarket", "corner shop"]
        case .unknown: return []
        }
    }
}

// MARK: - Place

struct Place: Identifiable {
    let id: String
    let name: String
    let category: PlaceCategory
    let coordinate: CLLocationCoordinate2D
    let address: String
    let hours: String?
    let isOpen: Bool?
    var distance: CLLocationDistance = 0
    var bearing: Double = 0
}

// MARK: - Place Extensions

extension Place {
    init(from mapItem: MKMapItem, userLocation: CLLocation) {
        self.id = mapItem.hashValue.description
        self.name = mapItem.name ?? "Unknown"
        self.category = PlaceCategory(from: mapItem)

        self.coordinate = mapItem.placemark.coordinate

        // Address formatting not fully available in current API version - simplified for now
        self.address = "Address unavailable"

        self.hours = nil
        self.isOpen = nil

        let placeLocation = CLLocation(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude)
        self.distance = userLocation.distance(from: placeLocation)
        self.bearing = Self.calculateBearing(from: userLocation.coordinate, to: self.coordinate)
    }

    private static func calculateBearing(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
        let lat1 = source.latitude.degreesToRadians
        let lon1 = source.longitude.degreesToRadians
        let lat2 = destination.latitude.degreesToRadians
        let lon2 = destination.longitude.degreesToRadians

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

        let radiansBearing = atan2(y, x)
        let degreesBearing = radiansBearing.radiansToDegrees

        return (degreesBearing + 360).truncatingRemainder(dividingBy: 360)
    }
}

// MARK: - Double Extensions

extension Double {
    var radians: Double {
        return self * .pi / 180
    }

    var degreesToRadians: Double {
        return self * .pi / 180
    }

    var radiansToDegrees: Double {
        return self * 180 / .pi
    }
}