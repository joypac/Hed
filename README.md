# Hed

> Capture raw thoughts in seconds. Organise them as floating visual bubbles.

## About

**Hed** is a focused iOS MVP that replaces the classic notes list with a free-floating canvas of rounded "bubbles". Each bubble is a single thought — draggable, categorisable, and satisfying to interact with.

No AI. No complex logic. Just fast input and a tactile canvas.

---

## Features

| Feature | Details |
|---|---|
| **Add thought** | Tap **+** → type or use live voice transcription (SFSpeechRecognizer) |
| **Free canvas** | Bubbles float at arbitrary positions on a vertically scrollable canvas |
| **Tap** | Opens the full text in a detail sheet |
| **Long press + drag** | Lifts the bubble (peers fade); drops it onto a category zone at the bottom |
| **Categories** | Ideas · To-do · Personal (hardcoded for MVP) |
| **Persistence** | All data stored locally in UserDefaults as JSON — no backend |

---

## Project structure

```
Hed/
├── HedApp.swift              # App entry point, injects NoteStore
├── ContentView.swift         # Root canvas: scrollable ZStack of bubbles
├── Models/
│   └── Note.swift            # Note struct + Category enum
├── ViewModels/
│   └── NoteStore.swift       # ObservableObject; CRUD + UserDefaults persistence
├── Views/
│   ├── BubbleView.swift      # Floating pill: tap / long-press-drag / colour per category
│   ├── AddNoteView.swift     # Sheet: TextEditor + voice button
│   ├── NoteDetailView.swift  # Full-text modal with delete
│   └── CategoryZonesView.swift  # Drop-zone strip shown during drag
└── Speech/
    └── SpeechRecognizer.swift   # SFSpeechRecognizer + AVAudioEngine wrapper
```

---

## Requirements

- **Xcode 15+**
- **iOS 17+** deployment target
- No third-party dependencies

### Permissions (Info.plist)

| Key | Purpose |
|---|---|
| `NSMicrophoneUsageDescription` | Voice input |
| `NSSpeechRecognitionUsageDescription` | Live transcription |

---

## Architecture

- **State**: single `NoteStore` (`ObservableObject`) injected via `@EnvironmentObject`
- **Persistence**: `JSONEncoder` → `UserDefaults` (key `hed_notes_v1`)
- **Gestures**: `LongPressGesture.sequenced(before: DragGesture)` — long press activates drag mode, drag moves the bubble; `coordinateSpace: .global` lets the drop-zone detector compare against screen-level Y position
- **No dependencies** beyond system frameworks (SwiftUI, Speech, AVFoundation)

---

## Roadmap (post-MVP)

- Create / rename / delete categories
- iCloud sync
- Widget for quick capture
- Haptic spring animations