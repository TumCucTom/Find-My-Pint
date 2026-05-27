import SwiftUI
import CoreLocation

struct CompassView: View {
    @ObservedObject var viewModel: PlaceViewModel
    @ObservedObject var locationManager = LocationManager.shared

    private var compassRotation: Double {
        guard let heading = locationManager.heading,
              let nearest = viewModel.nearestPlace else { return 0 }
        return nearest.bearing - heading.magneticHeading
    }

    private var directionString: String {
        guard let nearest = viewModel.nearestPlace else { return "--" }
        let normalizedBearing = ((nearest.bearing + 360).truncatingRemainder(dividingBy: 360))
        switch normalizedBearing {
        case 337.5..<360, 0..<22.5: return "N"
        case 22.5..<67.5: return "NE"
        case 67.5..<112.5: return "E"
        case 112.5..<157.5: return "SE"
        case 157.5..<202.5: return "S"
        case 202.5..<247.5: return "SW"
        case 247.5..<292.5: return "W"
        case 292.5..<337.5: return "NW"
        default: return "--"
        }
    }

    private func formatDistance(_ meters: CLLocationDistance) -> String {
        if meters < 1000 {
            return String(format: "%.0fm", meters)
        } else {
            return String(format: "%.1fkm", meters / 1000)
        }
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 280, height: 280)

                Image(systemName: "location.north.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .rotationEffect(.degrees(compassRotation))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: compassRotation)

                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 280, height: 280)

                VStack {
                    Text(directionString)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    Text("N")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 280, height: 280)

            if let place = viewModel.nearestPlace {
                VStack(spacing: 12) {
                    Text(place.category.icon)
                        .font(.system(size: 40))

                    Text(place.name)
                        .font(.system(size: 22, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)

                    Text(place.category.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 16) {
                        Label(formatDistance(place.distance), systemImage: "location.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)

                        if let hours = place.hours {
                            Label(hours, systemImage: "clock")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    if let isOpen = place.isOpen {
                        Text(isOpen ? "Open Now" : "Closed")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isOpen ? .green : .red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(isOpen ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                            )
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                )
                .padding(.horizontal, 24)
            } else if viewModel.isLoading {
                ProgressView("Finding beer...")
                    .padding(24)
            } else {
                Text("No beer nearby...\nkeep walking")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(24)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}