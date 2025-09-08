import SwiftUI

@main
struct Pocket_FlashcardsApp: App {
    // Create it once for the whole app lifecycle
    @StateObject private var store = DataStore(useMock: true)

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    HomeView()
                }
                .tabItem {
                    Image(systemName: "rectangle.stack")
                    Text("Decks")
                }

                ProgressViewScreen()
                    .tabItem {
                        Image(systemName: "chart.bar")
                        Text("Progress")
                    }
            }
            .environmentObject(store)   // <-- inject to everything inside TabView
            .environmentObject(DataStore(useMock: true, autosave: false))
        }
    }
}
