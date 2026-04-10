import SwiftUI

// ---------------------------------------------------------------------------
// MARK: - CategoryZonesView
// ---------------------------------------------------------------------------

/// A horizontal strip of drop-zone buttons that appears at the bottom of the
/// screen while the user is long-pressing/dragging a bubble.
///
/// Each zone corresponds to a named category (Uncategorized is excluded).
/// Tapping a zone commits the category change immediately (complementing the
/// coordinate-based detection in BubbleView for pure drag-and-drop).
struct CategoryZonesView: View {

    /// Height of this strip — shared with BubbleView for drop-zone detection.
    static let zoneStripHeight: CGFloat = 140

    let onCategorySelected: (Category) -> Void

    private let displayCategories = Category.allCases.filter { $0 != .uncategorized }

    var body: some View {
        VStack(spacing: 0) {
            // Cue label
            Text("Drop here to categorise")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 10)

            // Zone row
            HStack(spacing: 10) {
                ForEach(displayCategories) { category in
                    CategoryZone(category: category) {
                        onCategorySelected(category)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.regularMaterial)
    }
}

// MARK: - Single zone tile

private struct CategoryZone: View {
    let category: Category
    let onTap:    () -> Void

    @State private var isHighlighted = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                Text(category.emoji)
                    .font(.title3)
                Text(category.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .tertiarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    CategoryZonesView { _ in }
        .previewLayout(.sizeThatFits)
}
