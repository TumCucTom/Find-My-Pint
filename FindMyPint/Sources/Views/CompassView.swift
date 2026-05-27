import SwiftUI
import CoreLocation

struct CompassView: View {
    @ObservedObject var viewModel: PlaceViewModel
    @ObservedObject var locationManager = LocationManager.shared
    @Environment(\.colorScheme) var colorScheme

    private var dialRotation: Double {
        guard let heading = locationManager.heading else { return 0 }
        return -heading.magneticHeading
    }

    private var needleRotation: Double {
        guard let heading = locationManager.heading,
              let nearest = viewModel.nearestPlace else { return 0 }
        var angle = nearest.bearing - heading.magneticHeading
        while angle > 180 { angle -= 360 }
        while angle < -180 { angle += 360 }
        return angle
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

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        ZStack {
            (isDark ? Color(hex: "1a1a1a") : Color(hex: "F5F0E6"))
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 24) {
                    ZStack {
                        // Bezel
                        Circle()
                            .strokeBorder(
                                AngularGradient(
                                    colors: isDark
                                        ? [Color(hex: "888888"), Color(hex: "333333"), Color(hex: "888888"), Color(hex: "555555"), Color(hex: "333333")]
                                        : [Color(hex: "d4d4d4"), Color(hex: "a0a0a0"), Color(hex: "d4d4d4"), Color(hex: "b8b8b8"), Color(hex: "a0a0a0")],
                                    center: .center,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(360)
                                ),
                                lineWidth: 8
                            )
                            .frame(width: 300, height: 300)
                            .shadow(color: .black.opacity(isDark ? 0.4 : 0.15), radius: 8, x: 0, y: 4)

                        // Inner dial
                        Circle()
                            .fill(isDark ? Color(hex: "0d0d0d") : Color(hex: "FAF8F5"))
                            .frame(width: 280, height: 280)

                        // Rotating dial
                        ZStack {
                            ForEach(0..<72, id: \.self) { index in
                                Rectangle()
                                    .fill(index % 6 == 0
                                        ? (isDark ? .white : Color(hex: "333333"))
                                        : (isDark ? .white.opacity(0.4) : Color(hex: "333333").opacity(0.4))
                                    )
                                    .frame(width: index % 6 == 0 ? 2 : 1, height: index % 6 == 0 ? 16 : 8)
                                    .offset(y: -120)
                                    .rotationEffect(.degrees(Double(index) * 5))
                            }

                            ForEach(["N", "E", "S", "W"], id: \.self) { cardinal in
                                Text(cardinal)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(cardinal == "N"
                                        ? (isDark ? Color(hex: "ff3b30") : Color(hex: "c41e3a"))
                                        : (isDark ? .white : Color(hex: "333333"))
                                    )
                                    .offset(y: -100)
                                    .rotationEffect(.degrees(cardinal.degreesForCardinal))
                            }

                            ForEach([30, 60, 120, 150, 210, 240, 300, 330], id: \.self) { deg in
                                Text("\(deg)°")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(isDark ? .white.opacity(0.5) : Color(hex: "666666"))
                                    .offset(y: -100)
                                    .rotationEffect(.degrees(Double(deg)))
                            }
                        }
                        .rotationEffect(.degrees(dialRotation))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dialRotation)

                        // Needle
                        CompassNeedle(isDark: isDark)
                            .rotationEffect(.degrees(needleRotation))
                            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: needleRotation)

                        // Red triangle at top
                        Triangle()
                            .fill(isDark ? Color(hex: "ff3b30") : Color(hex: "c41e3a"))
                            .frame(width: 12, height: 16)
                            .offset(y: -150)
                    }
                    .frame(width: 300, height: 300)

                    // Info card
                    if let place = viewModel.nearestPlace {
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(isDark ? Color(hex: "2a2a2a") : Color(hex: "e8e4dc"))
                                        .frame(width: 52, height: 52)

                                    Text(place.category.icon)
                                        .font(.system(size: 26))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(place.name)
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(isDark ? .white : Color(hex: "222222"))
                                        .lineLimit(1)

                                    Text(place.category.rawValue.capitalized)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(isDark ? .white.opacity(0.5) : Color(hex: "666666"))
                                }

                                Spacer()

                                if let isOpen = place.isOpen {
                                    Text(isOpen ? "Open" : "Closed")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(isOpen
                                            ? (isDark ? Color(hex: "34c759") : Color(hex: "2e7d32"))
                                            : (isDark ? Color(hex: "ff3b30") : Color(hex: "c41e3a"))
                                        )
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(isOpen
                                                    ? (isDark ? Color(hex: "34c759").opacity(0.2) : Color(hex: "2e7d32").opacity(0.15))
                                                    : (isDark ? Color(hex: "ff3b30").opacity(0.2) : Color(hex: "c41e3a").opacity(0.15))
                                                )
                                        )
                                }
                            }

                            HStack(spacing: 32) {
                                VStack(spacing: 4) {
                                    Text("BEARING")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(isDark ? .white.opacity(0.4) : Color(hex: "999999"))
                                        .tracking(1)

                                    Text(directionString)
                                        .font(.system(size: 20, weight: .light, design: .rounded))
                                        .foregroundColor(isDark ? .white : Color(hex: "333333"))
                                }

                                Rectangle()
                                    .fill(isDark ? .white.opacity(0.1) : Color(hex: "dddddd"))
                                    .frame(width: 1, height: 30)

                                VStack(spacing: 4) {
                                    Text("DISTANCE")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(isDark ? .white.opacity(0.4) : Color(hex: "999999"))
                                        .tracking(1)

                                    Text(formatDistance(place.distance))
                                        .font(.system(size: 20, weight: .light, design: .rounded))
                                        .foregroundColor(isDark ? .white : Color(hex: "333333"))
                                }

                                Rectangle()
                                    .fill(isDark ? .white.opacity(0.1) : Color(hex: "dddddd"))
                                    .frame(width: 1, height: 30)

                                VStack(spacing: 4) {
                                    Text("TO DEST")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(isDark ? .white.opacity(0.4) : Color(hex: "999999"))
                                        .tracking(1)

                                    Text("\(Int(needleRotation))°")
                                        .font(.system(size: 20, weight: .light, design: .rounded))
                                        .foregroundColor(isDark ? .white : Color(hex: "333333"))
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(isDark ? Color(hex: "252525") : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(isDark ? .white.opacity(0.1) : Color(hex: "e0e0e0"), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(isDark ? 0.3 : 0.08), radius: 10, x: 0, y: 4)
                        )
                        .padding(.horizontal, 24)
                    } else if viewModel.isLoading {
                        ProgressView()
                            .tint(isDark ? .white : Color(hex: "333333"))
                            .scaleEffect(1.2)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "beer.slash")
                                .font(.system(size: 32))
                                .foregroundColor(isDark ? .white.opacity(0.3) : Color(hex: "999999"))

                            Text("No beer nearby...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(isDark ? .white.opacity(0.5) : Color(hex: "666666"))
                        }
                        .padding(24)
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Compass Needle
struct CompassNeedle: View {
    let isDark: Bool

    var body: some View {
        ZStack {
            NeedleTip()
                .fill(isDark ? Color(hex: "ff3b30") : Color(hex: "c41e3a"))
                .frame(width: 20, height: 70)
                .offset(y: -35)

            NeedleTip()
                .fill(isDark ? Color.white : Color(hex: "333333"))
                .frame(width: 20, height: 70)
                .rotationEffect(.degrees(180))
                .offset(y: 35)

            Circle()
                .fill(
                    RadialGradient(
                        colors: isDark ? [Color(hex: "666666"), Color(hex: "333333")] : [Color(hex: "888888"), Color(hex: "cccccc")],
                        center: .center,
                        startRadius: 0,
                        endRadius: 8
                    )
                )
                .frame(width: 16, height: 16)
        }
    }
}

struct NeedleTip: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY * 0.7),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

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
