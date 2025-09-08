import SwiftUI

struct EditCardView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    // Always pass the deck; pass `card` only when editing
    let deck: Deck
    let card: Card?

    // Local editable fields
    @State private var front: String
    @State private var back: String

    // Custom initializer so previews/callers stay simple
    init(deck: Deck, card: Card? = nil) {
        self.deck = deck
        self.card = card
        _front = State(initialValue: card?.frontText ?? "")
        _back  = State(initialValue: card?.backText  ?? "")
    }

    private var isEditing: Bool { card != nil }
    private var canSave: Bool {
        !front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !back .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Front") {
                    TextField("Question / prompt", text: $front, axis: .vertical)
                }
                Section("Back") {
                    TextField("Answer", text: $back, axis: .vertical)
                }
            }
            .navigationTitle(isEditing ? "Edit Card" : "New Card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedFront = front.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedBack  = back .trimmingCharacters(in: .whitespacesAndNewlines)

                        if let card {
                            // Update existing
                            store.updateCard(cardId: card.id, in: deck.id, front: trimmedFront, back: trimmedBack)
                        } else {
                            // Create new
                            store.addCard(front: trimmedFront, back: trimmedBack, to: deck.id)
                        }
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

#Preview {
    let store = DataStore(useMock: true)
    // New card preview
    return NavigationStack {
        if let d = store.decks.first {
            EditCardView(deck: d)
        } else {
            EditCardView(deck: Deck(id: UUID(), title: "French", cards: []))
        }
    }
    .environmentObject(store)
}

#Preview("Editing existing card") {
    let store = DataStore(useMock: true)
    let d = store.decks.first ?? Deck(id: UUID(), title: "French", cards: [])
    let c = d.cards.first ?? Card(frontText: "être — je", backText: "je sois", deckId: d.id)
    return NavigationStack {
        EditCardView(deck: d, card: c)
    }
    .environmentObject(store)
}
