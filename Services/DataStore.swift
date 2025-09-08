import Foundation
import Combine

final class DataStore: ObservableObject {
    @Published private(set) var decks: [Deck] = []

    private var cancellables = Set<AnyCancellable>()
    private let autosave: Bool

    /// `useMock`: seed with MockData when no saved file exists
    /// `autosave`: persist on every change (debounced)
    init(useMock: Bool = true, autosave: Bool = true) {
        self.autosave = autosave

        // Load from disk if present, else seed (optionally)
        if let saved = try? Persistence.load(), !saved.isEmpty {
            self.decks = saved
        } else {
            self.decks = useMock ? MockData.allDecks : []
            // Write the initial state so subsequent launches load
            try? Persistence.save(self.decks)
        }

        // Autosave on changes (small debounce to batch edits)
        if autosave {
            $decks
                .dropFirst()
                .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
                .sink { decks in
                    DispatchQueue.global(qos: .utility).async {
                        do { try Persistence.save(decks) }
                        catch { print("⚠️ Save failed:", error) }
                    }
                }
                .store(in: &cancellables)
        }
    }

    // MARK: - Public utility
    func saveNow() {
        DispatchQueue.global(qos: .utility).async {
            do { try Persistence.save(self.decks) }
            catch { print("⚠️ Manual save failed:", error) }
        }
    }

    func resetToMock() {
        decks = MockData.allDecks
        saveNow()
    }

    func deleteAll() {
        decks = []
        saveNow()
    }

    // MARK: - Decks
    func addDeck(title: String) {
        decks.append(Deck(title: title))
    }

    func renameDeck(_ id: UUID, to newTitle: String) {
        guard let i = decks.firstIndex(where: { $0.id == id }) else { return }
        decks[i].title = newTitle
    }

    func deleteDeck(_ id: UUID) {
        decks.removeAll { $0.id == id }
    }

    // MARK: - Cards
    func addCard(front: String, back: String, to deckId: UUID) {
        guard let i = decks.firstIndex(where: { $0.id == deckId }) else { return }
        var d = decks[i]
        d.cards.append(Card(frontText: front, backText: back, deckId: deckId))
        decks[i] = d // reassign to publish change
    }

    func updateCard(cardId: UUID, in deckId: UUID, front: String? = nil, back: String? = nil) {
        guard let di = decks.firstIndex(where: { $0.id == deckId }) else { return }
        guard let ci = decks[di].cards.firstIndex(where: { $0.id == cardId }) else { return }
        var d = decks[di]
        if let front { d.cards[ci].frontText = front }
        if let back  { d.cards[ci].backText  = back  }
        decks[di] = d
    }

    func deleteCard(_ cardId: UUID, from deckId: UUID) {
        guard let di = decks.firstIndex(where: { $0.id == deckId }) else { return }
        var d = decks[di]
        d.cards.removeAll { $0.id == cardId }
        decks[di] = d
    }

    func moveCards(in deckId: UUID, from source: IndexSet, to destination: Int) {
        guard let di = decks.firstIndex(where: { $0.id == deckId }) else { return }
        var d = decks[di]
        d.cards.move(fromOffsets: source, toOffset: destination)
        decks[di] = d
    }
    
    // Shuffle the stored order of cards in a deck
    func shuffleDeck(_ deckId: UUID) {
        guard let i = decks.firstIndex(where: { $0.id == deckId }) else { return }
        var d = decks[i]
        d.cards.shuffle()
        decks[i] = d   // reassign so @Published updates
    }
    
    // Add many cards at once
    func addCards(_ pairs: [(String, String)], to deckId: UUID) {
        guard let i = decks.firstIndex(where: { $0.id == deckId }) else { return }
        var d = decks[i]
        for (front, back) in pairs {
            let f = front.trimmingCharacters(in: .whitespacesAndNewlines)
            let b = back .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !f.isEmpty, !b.isEmpty else { continue }
            d.cards.append(Card(frontText: f, backText: b, deckId: deckId))
        }
        decks[i] = d // publish change
    }


}
