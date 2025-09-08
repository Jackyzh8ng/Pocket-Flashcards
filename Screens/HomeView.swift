import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: DataStore
    @State private var showingAddDeck = false

       @State private var searchText = ""

       private var query: String {
           searchText.trimmingCharacters(in: .whitespacesAndNewlines)
       }
       private var filteredDecks: [Deck] {
           guard !query.isEmpty else { return store.decks }
           return store.decks.filter { $0.title.localizedCaseInsensitiveContains(query) }
       }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.decks) { deck in
                    NavigationLink {
                        DeckDetailView(deck:deck)   // pass id (safer than passing copies)
                    } label: {
                        HStack {
                            Text(deck.title).font(.headline)
                            Spacer()
                            Text("\(deck.cardCount) cards")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.map { store.decks[$0].id }.forEach(store.deleteDeck)
                }
            }
            .navigationTitle("Pocket Flashcards")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddDeck = true
                    } label: { Image(systemName: "plus") }
                }
            }
            
            .sheet(isPresented: $showingAddDeck) {
                AddDeckView()
            }
        }
    }
}
