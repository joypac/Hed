import SwiftUI

@main
struct HedApp: App {
    // Single store instance shared across the whole app
    @StateObject private var store = NoteStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
