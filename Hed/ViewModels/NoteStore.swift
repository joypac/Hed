import Foundation
import Combine

/// Single source of truth for all notes.
/// Automatically persists to UserDefaults as JSON.
final class NoteStore: ObservableObject {

    @Published private(set) var notes: [Note] = []

    /// Set if JSON encoding/decoding fails; observe to surface in UI if desired.
    @Published private(set) var persistenceError: Error? = nil

    private let persistenceKey = "hed_notes_v1"

    init() { load() }

    // MARK: - Mutations

    func add(_ note: Note) {
        notes.append(note)
        persist()
    }

    func updatePosition(id: UUID, x: Double, y: Double) {
        guard let i = index(of: id) else { return }
        notes[i].positionX = x
        notes[i].positionY = y
        persist()
    }

    func setCategory(_ category: Category, for id: UUID) {
        guard let i = index(of: id) else { return }
        notes[i].category = category
        persist()
    }

    func delete(id: UUID) {
        notes.removeAll { $0.id == id }
        persist()
    }

    // MARK: - Persistence

    private func persist() {
        do {
            let data = try JSONEncoder().encode(notes)
            UserDefaults.standard.set(data, forKey: persistenceKey)
            persistenceError = nil
        } catch {
            persistenceError = error
            #if DEBUG
            print("[NoteStore] Failed to persist notes: \(error)")
            #endif
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else { return }
        do {
            notes = try JSONDecoder().decode([Note].self, from: data)
        } catch {
            persistenceError = error
            #if DEBUG
            print("[NoteStore] Failed to load notes: \(error)")
            #endif
        }
    }

    // MARK: - Helpers

    private func index(of id: UUID) -> Int? {
        notes.firstIndex { $0.id == id }
    }
}
