import SwiftUI

// ---------------------------------------------------------------------------
// MARK: - BubbleView
// ---------------------------------------------------------------------------

/// A single floating thought displayed as a rounded, coloured pill.
///
/// Interaction model:
///   • Tap  → opens detail sheet (handled by parent)
///   • Long press (≥ 0.4 s) + drag → moves the bubble around the canvas;
///     dropping it onto the category zone strip at the bottom categorises it.
struct BubbleView: View {

    let note:                  Note
    let isDimmed:              Bool          // true while *another* bubble is being dragged
    let onTap:                 () -> Void
    let onDragStarted:         () -> Void
    let onDragEnded:           (_ newX: Double, _ newY: Double) -> Void
    let onDroppedOnCategory:   (Category) -> Void

    // Live translation tracked by the gesture recogniser; auto-resets on end.
    @GestureState private var dragState: DragState = .inactive

    // Guards against firing onDragStarted more than once per gesture.
    @State private var longPressActive = false

    // Visual constants
    private let bubbleW: CGFloat = 144
    private let bubbleH: CGFloat = 70

    // Gesture timing
    private let longPressDuration: Double = 0.4

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(bubbleColor)
                .shadow(
                    color: .black.opacity(isDimmed ? 0.04 : (dragState.isActive ? 0.22 : 0.10)),
                    radius: dragState.isActive ? 18 : 6,
                    y:      dragState.isActive ?  8 : 3
                )

            Text(note.text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
        }
        .frame(width: bubbleW, height: bubbleH)
        // Lift & scale while being dragged
        .scaleEffect(dragState.isActive ? 1.07 : 1.0)
        // Dim this bubble when another one is being manipulated
        .opacity(isDimmed ? 0.4 : 1.0)
        // Translate in real-time during the drag; resets when gesture ends
        .offset(dragState.translation)
        .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.72), value: dragState.isActive)
        .animation(.easeInOut(duration: 0.2), value: isDimmed)
        .gesture(dragGesture)
        .simultaneousGesture(tapGesture)
    }

    // MARK: - Colour

    /// Soft pastel tint unique to each category — no asset catalogue entry needed.
    private var bubbleColor: Color {
        switch note.category {
        case .uncategorized: return Color(hue: 0.60, saturation: 0.08, brightness: 0.96)
        case .ideas:         return Color(hue: 0.14, saturation: 0.22, brightness: 0.98)
        case .todo:          return Color(hue: 0.57, saturation: 0.18, brightness: 0.97)
        case .personal:      return Color(hue: 0.36, saturation: 0.18, brightness: 0.96)
        }
    }

    // MARK: - Gestures

    private var tapGesture: some Gesture {
        TapGesture().onEnded { onTap() }
    }

    private var dragGesture: some Gesture {
        // Phase 1 — long press activates "drag mode" (fades peers, shows zones)
        // Phase 2 — standard drag repositions the bubble
        LongPressGesture(minimumDuration: longPressDuration)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
            .updating($dragState) { value, state, _ in
                switch value {
                case .first(true):
                    state = .pressing
                case .second(true, let drag?):
                    state = .dragging(translation: drag.translation)
                default:
                    break
                }
            }
            .onChanged { value in
                // Fire onDragStarted exactly once when the long press succeeds
                if case .first(true) = value, !longPressActive {
                    longPressActive = true
                    onDragStarted()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
            .onEnded { value in
                longPressActive = false

                if case .second(true, let drag?) = value {
                    let screenH = UIScreen.main.bounds.height
                    let screenW = UIScreen.main.bounds.width

                    // Use the shared strip height constant from CategoryZonesView
                    let zoneH = CategoryZonesView.zoneStripHeight

                    if drag.location.y > screenH - zoneH {
                        // Dropped onto the category zone strip — pick the zone by X position
                        let cats      = Category.allCases.filter { $0 != .uncategorized }
                        let zoneWidth = screenW / CGFloat(cats.count)
                        let idx       = min(max(Int(drag.location.x / zoneWidth), 0), cats.count - 1)
                        onDroppedOnCategory(cats[idx])
                    } else {
                        // Moved to a new free position
                        let newX = note.positionX + drag.translation.width
                        let newY = note.positionY + drag.translation.height
                        onDragEnded(newX, newY)
                    }
                } else {
                    // Long press fired but no drag occurred — keep current position
                    onDragEnded(note.positionX, note.positionY)
                }
            }
    }
}

// MARK: - Drag State

private enum DragState: Equatable {
    case inactive
    case pressing
    case dragging(translation: CGSize)

    var translation: CGSize {
        if case .dragging(let t) = self { return t }
        return .zero
    }

    var isActive: Bool {
        switch self {
        case .inactive: return false
        default:        return true
        }
    }
}
