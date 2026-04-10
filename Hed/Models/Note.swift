import Foundation

// ---------------------------------------------------------------------------
// MARK: - Category
// ---------------------------------------------------------------------------

/// Hardcoded categories for the MVP — no creation or editing needed yet.
enum Category: String, CaseIterable, Codable, Identifiable {
    case uncategorized = "Uncategorized"
    case ideas         = "Ideas"
    case todo          = "To-do"
    case personal      = "Personal"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .uncategorized: return "💭"
        case .ideas:         return "💡"
        case .todo:          return "✅"
        case .personal:      return "🌿"
        }
    }
}

// ---------------------------------------------------------------------------
// MARK: - Note
// ---------------------------------------------------------------------------

/// A single captured thought.
struct Note: Identifiable, Codable {
    let id: UUID
    var text:      String
    var category:  Category

    /// Absolute position on the free-floating canvas (points).
    var positionX: Double
    var positionY: Double

    let createdAt: Date

    init(
        id:        UUID     = UUID(),
        text:      String,
        category:  Category = .uncategorized,
        positionX: Double   = 195,
        positionY: Double   = 300
    ) {
        self.id        = id
        self.text      = text
        self.category  = category
        self.positionX = positionX
        self.positionY = positionY
        self.createdAt = Date()
    }
}
