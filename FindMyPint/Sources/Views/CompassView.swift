import SwiftUI
import CoreLocation

struct CompassView: View {
    @ObservedObject var viewModel: PlaceViewModel
    @ObservedObject var locationManager = LocationManager.shared

    private var compassRotation: Double {
        guard let nearest = viewModel.nearestPlace else { return 0 }
        // Arrow always points to destination - rotate by absolute bearing
        return nearest.bearing
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

    private var headingDegrees: Int {
        guard let heading = locationManager.heading else { return 0 }
        return Int(heading.magneticHeading)
    }

    private func formatDistance(_ meters: CLLocationDistance) -> String {
        if meters < 1000 {
            return String(format: "%.0fm", meters)
        } else {
            return String(format: "%.1fkm", meters / 1000)
        }
    }

    var body: some View {
        ZStack {
            // Deep gradient background
            LinearGradient(
                colors: [
                    Color(hex: "0f0c29"),
                    Color(hex: "302b63"),
                    Color(hex: "24243e")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // Compass instrument
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 300, height: 300)
                        .blur(radius: 2)

                    // Glass outer ring
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.4)
                                ],
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 300, height: 300)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )

                    // Tick marks
                    ForEach(0..<60, id: \.self) { index in
                        Rectangle()
                            .fill(Color.white.opacity(index % 5 == 0 ? 0.6 : 0.2))
                            .frame(width: index % 5 == 0 ? 2 : 1, height: index % 5 == 0 ? 12 : 6)
                            .offset(y: -130)
                            .rotationEffect(.degrees(Double(index) * 6))
                    }

                    // Cardinal direction labels
                    ForEach(["N", "E", "S", "W"], id: \.self) { cardinal in
                        Text(cardinal)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .offset(y: -110)
                            .rotationEffect(.degrees(cardinal.degreesForCardinal))
                    }

                    // Center heading display
                    VStack(spacing: 4) {
                        Text("\(headingDegrees)")
                            .font(.system(size: 48, weight: .ultraLight, design: .rounded))
                            .foregroundColor(.white)

                        Text("°")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(.white.opacity(0.6))
                            .offset(x: 12, y: -8)
                    }

                    // Direction needle - points to destination
                    CompassNeedle()
                        .rotationEffect(.degrees(compassRotation))
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: compassRotation)
                        .offset(y: -60)

                    // Fixed north indicator
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                        .offset(y: -145)
                }
                .frame(width: 300, height: 300)

                // Info card
                if let place = viewModel.nearestPlace {
                    GlassCard {
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "7b2ff7").opacity(0.4), Color(hex: "00d4ff").opacity(0.4)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 56, height: 56)

                                    Text(place.category.icon)
                                        .font(.system(size: 28))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(place.name)
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    Text(place.category.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                }

                                Spacer()
                            }

                            Divider()
                                .background(Color.white.opacity(0.2))

                            HStack(spacing: 24) {
                                // Distance
                                VStack(spacing: 4) {
                                    Text("DISTANCE")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.4))
                                        .tracking(1)

                                    Text(formatDistance(place.distance))
                                        .font(.system(size: 22, weight: .light, design: .rounded))
                                        .foregroundColor(.white)
                                }

                                Spacer()

                                // Direction
                                VStack(spacing: 4) {
                                    Text("BEARING")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.4))
                                        .tracking(1)

                                    Text(directionString)
                                        .font(.system(size: 22, weight: .light, design: .rounded))
                                        .foregroundColor(.white)
                                }

                                Spacer()

                                // Status
                                if let isOpen = place.isOpen {
                                    VStack(spacing: 4) {
                                        Text("STATUS")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.4))
                                            .tracking(1)

                                        Text(isOpen ? "OPEN" : "CLOSED")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(isOpen ? Color(hex: "00ff88") : Color(hex: "ff4757"))
                                    }
                                }
                            }

                            if let hours = place.hours {
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.4))

                                    Text(hours)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.6))

                                    Spacer()
                                }
                            }
                        }
                        .padding(20)
                    }
                    .padding(.horizontal, 24)
                } else if viewModel.isLoading {
                    GlassCard {
                        HStack(spacing: 16) {
                            ProgressView()
                                .tint(.white)

                            Text("Searching for beer...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 24)
                } else {
                    GlassCard {
                        VStack(spacing: 12) {
                            Image(systemName: "beer.slash")
                                .font(.system(size: 36))
                                .foregroundColor(.white.opacity(0.4))

                            Text("No beer nearby...")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))

                            Text("Keep walking")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
            .padding(.top, 60)
        }
    }
}

// MARK: - Compass Needle
struct CompassNeedle: View {
    var body: some View {
        ZStack {
            // Needle shadow/glow
            NeedleShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "00d4ff").opacity(0.6), Color(hex: "00d4ff").opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blur(radius: 4)
                .scaleEffect(x: 1.2, y: 1.1)

            // Main needle - cyan tip pointing to destination
            NeedleShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "00d4ff"), Color(hex: "0099cc")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Needle highlight
            NeedleShape()
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                .scaleEffect(x: 0.95, y: 0.95)

            // Center pivot
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white, Color.white.opacity(0.5)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 6
                    )
                )
                .frame(width: 12, height: 12)
        }
        .frame(width: 24, height: 80)
    }
}

struct NeedleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Pointed top (direction of destination)
        path.move(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: width, y: height * 0.7))
        path.addQuadCurve(
            to: CGPoint(x: width / 2, y: height),
            control: CGPoint(x: width / 2, y: height * 0.85)
        )
        path.addQuadCurve(
            to: CGPoint(x: 0, y: height * 0.7),
            control: CGPoint(x: width / 2, y: height * 0.85)
        )
        path.closeSubpath()

        return path
    }
}

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - String Extension
extension String {
    var degreesForCardinal: Double {
        switch self {
        case "N": return 0
        case "E": return 90
        case "S": return 180
        case "W": return 270
        default: return 0
        }
    }
}
