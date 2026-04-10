import SwiftUI

// ---------------------------------------------------------------------------
// MARK: - NoteDetailView
// ---------------------------------------------------------------------------

/// Full-text modal shown when the user taps a bubble.
struct NoteDetailView: View {

    let note:     Note
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Full text
                    Text(note.text)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    // Category badge
                    Label {
                        Text(note.category.rawValue)
                    } icon: {
                        Text(note.category.emoji)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    // Created date
                    Label(
                        note.createdAt.formatted(date: .abbreviated, time: .shortened),
                        systemImage: "clock"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Thought")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .tint(.red)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NoteDetailView(
        note: Note(text: "A sample thought that could be quite long when fully expanded."),
        onDelete: {}
    )
}
