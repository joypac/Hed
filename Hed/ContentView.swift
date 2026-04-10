import SwiftUI

// ---------------------------------------------------------------------------
// MARK: - ContentView
// ---------------------------------------------------------------------------

/// Root view: a large, vertically scrollable canvas of floating bubbles.
///
/// States:
///   • **Idle**        — show all bubbles + add button
///   • **Drag mode**   — a bubble is long-pressed; peers fade, category zones
///                       appear at the bottom; scroll is disabled
///   • **Detail**      — user tapped a bubble; full-text sheet is presented
struct ContentView: View {

    @EnvironmentObject private var store: NoteStore

    // UUID of the bubble currently being dragged (nil = idle)
    @State private var activeDragID: UUID? = nil

    // Note opened in the detail sheet (nil = no sheet)
    @State private var selectedNote: Note? = nil

    // Controls the Add Note sheet
    @State private var showingAddNote = false

    // Canvas is taller than the screen so bubbles can be spread vertically
    private let canvasHeight: CGFloat = 2000

    // Inset from canvas edges so bubbles never clip off-screen
    private let bubbleEdgeInset: Double = 80

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {

                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                // ── Scrollable bubble canvas ──────────────────────────────
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // Invisible spacer that defines the canvas dimensions
                        Color.clear
                            .frame(width: geo.size.width, height: canvasHeight)

                        ForEach(store.notes) { note in
                            BubbleView(
                                note:    note,
                                isDimmed: activeDragID != nil && activeDragID != note.id,
                                onTap: {
                                    // Only open detail when nothing is being dragged
                                    guard activeDragID == nil else { return }
                                    selectedNote = note
                                },
                                onDragStarted: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        activeDragID = note.id
                                    }
                                },
                                onDragEnded: { newX, newY in
                                    // Clamp so bubbles stay on-canvas
                                    let clampedX = newX.clamped(to: bubbleEdgeInset...(Double(geo.size.width) - bubbleEdgeInset))
                                    let clampedY = newY.clamped(to: bubbleEdgeInset...(Double(canvasHeight) - bubbleEdgeInset))
                                    store.updatePosition(id: note.id, x: clampedX, y: clampedY)
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        activeDragID = nil
                                    }
                                },
                                onDroppedOnCategory: { category in
                                    store.setCategory(category, for: note.id)
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        activeDragID = nil
                                    }
                                }
                            )
                            // Position is stored as absolute canvas coordinates
                            .position(x: note.positionX, y: note.positionY)
                        }
                    }
                }
                // Disable scroll while dragging so the DragGesture wins
                .scrollDisabled(activeDragID != nil)

                // ── Category zone strip (visible during drag only) ────────
                if activeDragID != nil {
                    CategoryZonesView { category in
                        if let id = activeDragID {
                            store.setCategory(category, for: id)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            activeDragID = nil
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
                }

                // ── Floating add button (hidden while dragging) ───────────
                if activeDragID == nil {
                    AddButton { showingAddNote = true }
                        .padding(.bottom, 50)
                        .zIndex(5)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: activeDragID != nil)

        // New-thought sheet
        .sheet(isPresented: $showingAddNote) {
            AddNoteView { text in
                // Spread new bubbles across the canvas, adapting to actual screen width
                let maxX = Double(geo.size.width) - bubbleEdgeInset
                let x = Double.random(in: bubbleEdgeInset...maxX)
                let y = Double.random(in: 100...600)
                store.add(Note(text: text, positionX: x, positionY: y))
            }
        }

        // Detail sheet (tap on bubble)
        .sheet(item: $selectedNote) { note in
            NoteDetailView(note: note) {
                store.delete(id: note.id)
                selectedNote = nil
            }
        }
    }
}

// ---------------------------------------------------------------------------
// MARK: - Add Button
// ---------------------------------------------------------------------------

private struct AddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        }
        .accessibilityLabel("Add thought")
    }
}

// ---------------------------------------------------------------------------
// MARK: - Comparable clamping helper
// ---------------------------------------------------------------------------

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject({
            let store = NoteStore()
            store.add(Note(text: "Design the onboarding", category: .ideas,    positionX: 80,  positionY: 120))
            store.add(Note(text: "Buy groceries",          category: .todo,     positionX: 240, positionY: 200))
            store.add(Note(text: "Call mum on Sunday",     category: .personal, positionX: 140, positionY: 320))
            store.add(Note(text: "Rethink the bubble colours",                  positionX: 270, positionY: 440))
            return store
        }())
}
