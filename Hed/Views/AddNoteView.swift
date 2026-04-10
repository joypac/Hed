import SwiftUI

// ---------------------------------------------------------------------------
// MARK: - AddNoteView
// ---------------------------------------------------------------------------

/// Modal sheet for capturing a new thought via keyboard or voice.
struct AddNoteView: View {

    let onSubmit: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var speech = SpeechRecognizer()
    @State private var text = ""
    @State private var showPermissionAlert = false
    @FocusState private var isTextEditorFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                // ── Text input ────────────────────────────────────────────
                TextEditor(text: $text)
                    .font(.body)
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .focused($isTextEditorFocused)
                    .frame(minHeight: 130)

                // ── Voice button ──────────────────────────────────────────
                Button {
                    handleVoiceButton()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: speech.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.title2)
                        Text(speech.isRecording ? "Stop" : "Use Voice")
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(speech.isRecording ? .red : .accentColor)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill((speech.isRecording ? Color.red : Color.accentColor).opacity(0.12))
                    )
                }
                .disabled(!speech.isAvailable && !speech.isRecording)

                Spacer()
            }
            .padding()
            .navigationTitle("New Thought")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        speech.stopRecording()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { submit() }
                        .fontWeight(.semibold)
                        .disabled(trimmed.isEmpty)
                }
            }
            .alert("Permission Required", isPresented: $showPermissionAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enable Microphone and Speech Recognition in Settings to use voice input.")
            }
        }
        .onAppear {
            isTextEditorFocused = true
        }
        // Sync live speech transcript → text field
        .onChange(of: speech.transcript) { _, newValue in
            if !newValue.isEmpty { text = newValue }
        }
        .onDisappear {
            speech.stopRecording()
        }
    }

    // MARK: - Helpers

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func submit() {
        guard !trimmed.isEmpty else { return }
        speech.stopRecording()
        onSubmit(trimmed)
        dismiss()
    }

    private func handleVoiceButton() {
        if speech.isRecording {
            speech.stopRecording()
            return
        }
        speech.requestAuthorization { granted in
            if granted {
                speech.startRecording()
            } else {
                showPermissionAlert = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddNoteView { _ in }
}
