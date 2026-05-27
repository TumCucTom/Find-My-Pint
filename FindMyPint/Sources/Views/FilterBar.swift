import SwiftUI

struct FilterBar: View {
    @ObservedObject var viewModel: PlaceViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // All / None quick toggles
                QuickFilterChip(
                    title: "All",
                    icon: "checkmark.circle.fill",
                    isSelected: viewModel.activeFilters.count == PlaceCategory.allCases.count
                ) {
                    viewModel.setAllFilters(true)
                }

                QuickFilterChip(
                    title: "None",
                    icon: "xmark.circle.fill",
                    isSelected: viewModel.activeFilters.isEmpty
                ) {
                    viewModel.setAllFilters(false)
                }

                Divider()
                    .frame(height: 24)

                // Category filters
                ForEach(PlaceCategory.allCases) { category in
                    FilterChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: viewModel.activeFilters.contains(category)
                    ) {
                        viewModel.toggleFilter(category)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "0f0c29").opacity(0.95),
                    Color(hex: "302b63").opacity(0.95)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
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
                        ? AnyShapeStyle(LinearGradient(
                            colors: [Color(hex: "00d4ff").opacity(0.3), Color(hex: "7b2ff7").opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        : AnyShapeStyle(Color.white.opacity(0.1))
                    )
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color(hex: "00d4ff").opacity(0.5) : Color.clear, lineWidth: 1)
            )
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
    }
}

struct QuickFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
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
                        ? Color.white.opacity(0.2)
                        : Color.white.opacity(0.05)
                    )
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
            )
            .foregroundColor(.white.opacity(isSelected ? 1 : 0.6))
        }
        .buttonStyle(.plain)
    }
}
