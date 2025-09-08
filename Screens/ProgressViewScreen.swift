import SwiftUI

struct ProgressViewScreen: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        List {
            let deckCount  = store.decks.count
            let cardCount  = store.decks.reduce(0) { $0 + $1.cardCount }

            Section("Totals") {
                LabeledContent("Decks", value: "\(deckCount)")
                LabeledContent("Cards", value: "\(cardCount)")
            }

            Section("By Deck") {
                ForEach(store.decks) { deck in
                    LabeledContent(deck.title, value: "\(deck.cardCount) cards")
                }
            }
        }
        .navigationTitle("Progress")
    }
}
