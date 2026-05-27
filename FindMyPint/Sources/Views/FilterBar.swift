import SwiftUI

struct FilterBar: View {
    @ObservedObject var viewModel: PlaceViewModel
    @Environment(\.colorScheme) var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                QuickFilterChip(
                    title: "All",
                    icon: "checkmark.circle.fill",
                    isSelected: viewModel.activeFilters.count == PlaceCategory.allCases.count,
                    isDark: isDark
                ) {
                    viewModel.setAllFilters(true)
                }

                QuickFilterChip(
                    title: "None",
                    icon: "xmark.circle.fill",
                    isSelected: viewModel.activeFilters.isEmpty,
                    isDark: isDark
                ) {
                    viewModel.setAllFilters(false)
                }

                Divider()
                    .frame(height: 24)

                ForEach(PlaceCategory.allCases) { category in
                    FilterChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: viewModel.activeFilters.contains(category),
                        isDark: isDark
                    ) {
                        viewModel.toggleFilter(category)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(
            (isDark ? Color(hex: "1a1a1a") : Color(hex: "F5F0E6")).opacity(0.98)
        )
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let isDark: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(icon)
                    .font(.system(size: 14))

                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected
                        ? (isDark ? Color(hex: "ff3b30").opacity(0.25) : Color(hex: "c41e3a").opacity(0.15))
                        : (isDark ? .white.opacity(0.08) : Color(hex: "e8e4dc"))
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected
                            ? (isDark ? Color(hex: "ff3b30").opacity(0.6) : Color(hex: "c41e3a").opacity(0.4))
                            : .clear,
                        lineWidth: 1
                    )
            )
            .foregroundColor(isSelected
                ? (isDark ? Color(hex: "ff3b30") : Color(hex: "c41e3a"))
                : (isDark ? .white.opacity(0.7) : Color(hex: "444444"))
            )
        }
        .buttonStyle(.plain)
    }
}

struct QuickFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let isDark: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected
                        ? (isDark ? .white.opacity(0.15) : Color(hex: "dddddd"))
                        : (isDark ? .white.opacity(0.05) : Color(hex: "eeeeee"))
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected
                            ? (isDark ? .white.opacity(0.3) : Color(hex: "cccccc"))
                            : (isDark ? .white.opacity(0.1) : Color(hex: "dddddd")),
                        lineWidth: 1
                    )
            )
            .foregroundColor(isDark
                ? (.white.opacity(isSelected ? 1 : 0.5))
                : (Color(hex: "333333").opacity(isSelected ? 1 : 0.5))
            )
        }
        .buttonStyle(.plain)
    }
}
