import SwiftUI

struct DeckDetailView: View {
    @EnvironmentObject var store: DataStore

    let deck: Deck
    @State private var showAddCard   = false
    @State private var startStudy    = false
    @State private var editingCard: Card?
    @State private var renamingDeck  = false
    @State private var startQuiz     = false
    @State private var showBulkAdd   = false
    @State private var startStudyMarked = false

    @State private var searchText = ""

    // Always reflect latest deck state
    private var liveDeck: Deck? { store.decks.first(where: { $0.id == deck.id }) }
    private var isFiltering: Bool { !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private func filteredCards(for deck: Deck) -> [Card] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return deck.cards }
        return deck.cards.filter {
            $0.frontText.localizedCaseInsensitiveContains(q) ||
            $0.backText.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        Group {
            if let d = liveDeck {
                List {
                    // Header actions (no Study/Quiz here)
                    HeaderSection(
                        cardCount: d.cardCount,
                        markedCount: store.markedCount(d.id),
                        onShuffle: { store.shuffleDeck(d.id); startStudy = true },
                        onStudyMarked: { startStudyMarked = true }
                    )

                    // Add & Bulk Add row right above the cards
                    AddRowSection(
                        onAdd: { showAddCard = true },
                        onBulkAdd: { showBulkAdd = true }
                    )

                    // Cards list (scrollable)
                    CardsSection(
                        deck: d,
                        cards: filteredCards(for: d),
                        allowMove: !isFiltering,
                        onEdit: { editingCard = $0 },
                        onDelete: { cardId in store.deleteCard(cardId, from: d.id) },
                        onMove: { src, dst in store.moveCards(in: d.id, from: src, to: dst) }
                    )
                }
                .navigationTitle(d.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { EditButton() }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { renamingDeck = true } label: { Label("Rename", systemImage: "pencil") }
                    }
                }
                // Bottom bar: Study + Quiz
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 0) {
                        Divider()
                        HStack(spacing: 12) {
                            Button {
                                startStudy = true
                            } label: {
                                Label("Study \(d.cardCount)", systemImage: "book.fill")
                                    .frame(maxWidth: .infinity, minHeight: 56)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(d.cardCount == 0)

                            Button {
                                store.shuffleDeck(d.id)
                                startQuiz = true
                            } label: {
                                Label("Quiz", systemImage: "exclamationmark.triangle.fill")
                                    .frame(maxWidth: .infinity, minHeight: 56)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .disabled(d.cardCount == 0)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    }
                    .background(.bar)
                }
                // Sheets / navigation
                .sheet(isPresented: $showAddCard) {
                    EditCardView(deck: d).environmentObject(store)
                }
                .sheet(item: $editingCard) { card in
                    EditCardView(deck: d, card: card).environmentObject(store)
                }
                .sheet(isPresented: $renamingDeck) {
                    RenameDeckView(deck: d).environmentObject(store)
                }
                .sheet(isPresented: $showBulkAdd) {
                    BulkAddCardsView(deckId: d.id).environmentObject(store)
                }
                .navigationDestination(isPresented: $startStudy) {
                    if let fresh = store.decks.first(where: { $0.id == deck.id }) {
                        StudyView(deck: fresh).environmentObject(store)
                    } else {
                        ContentUnavailableView("Deck not found", systemImage: "exclamationmark.triangle")
                    }
                }
                .navigationDestination(isPresented: $startQuiz) {
                    if let fresh = store.decks.first(where: { $0.id == deck.id }) {
                        QuizView(deck: fresh)
                            .navigationBarBackButtonHidden(true)
                            .environmentObject(store)
                    } else {
                        ContentUnavailableView("Deck not found", systemImage: "exclamationmark.triangle")
                    }
                }
                .navigationDestination(isPresented: $startStudyMarked) {
                    if let fresh = store.decks.first(where: { $0.id == deck.id }) {
                        let onlyMarked = fresh.cards.filter { $0.isMarked }
                        StudyView(deck: fresh, cardsOverride: onlyMarked)
                            .environmentObject(store)
                    } else {
                        ContentUnavailableView("Deck not found", systemImage: "exclamationmark.triangle")
                    }
                }
                .searchable(text: $searchText,
                            placement: .navigationBarDrawer(displayMode: .automatic),
                            prompt: "Search cards")
            } else {
                ContentUnavailableView("Deck not found", systemImage: "exclamationmark.triangle")
            }
        }
    }
}

// MARK: - Sections

private struct HeaderSection: View {
    let cardCount: Int
    let markedCount: Int
    let onShuffle: () -> Void
    let onStudyMarked: () -> Void

    var body: some View {
        Section {
            Text("\(cardCount) cards")
                .foregroundStyle(.secondary)

            HStack {
                Button { onShuffle() } label: {
                    Label("Shuffle & Study", systemImage: "shuffle")
                }
                .buttonStyle(.bordered)
                .disabled(cardCount == 0)

                Button {
                    onStudyMarked()
                } label: {
                    Label("Study Marked (\(markedCount))", systemImage: "bookmark")
                }
                .buttonStyle(.bordered)
                .disabled(markedCount == 0)
            }
        }
    }
}

private struct AddRowSection: View {
    let onAdd: () -> Void
    let onBulkAdd: () -> Void

    var body: some View {
        Section {
            HStack {
                Button(action: onAdd) {
                    Label("Add Card", systemImage: "plus")
                }
                .buttonStyle(.bordered)

                Spacer(minLength: 12)

                Button(action: onBulkAdd) {
                    Label("Bulk Add", systemImage: "text.badge.plus")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

private struct CardsSection: View {
    let deck: Deck
    let cards: [Card]
    let allowMove: Bool
    let onEdit: (Card) -> Void
    let onDelete: (UUID) -> Void
    let onMove: (IndexSet, Int) -> Void

    var body: some View {
        Section {
            if allowMove {
                ForEach(cards) { card in
                    cardRow(card)
                }
                .onDelete(perform: delete)
                .onMove(perform: onMove)
            } else {
                ForEach(cards) { card in
                    cardRow(card)
                }
                .onDelete(perform: delete)
                .moveDisabled(true)
            }
        }
    }

    @ViewBuilder
    private func cardRow(_ card: Card) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.frontText).bold()
            Text(card.backText).foregroundStyle(.secondary)
        }
        .swipeActions {
            Button("Edit") { onEdit(card) }.tint(.blue)
            Button(role: .destructive) { onDelete(card.id) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func delete(_ offsets: IndexSet) {
        let ids = offsets.map { cards[$0].id }
        ids.forEach(onDelete)
    }
}

#Preview {
    let store = DataStore(useMock: true)
    return NavigationStack {
        if let first = store.decks.first {
            DeckDetailView(deck: first)
        } else {
            DeckDetailView(deck: Deck(id: UUID(), title: "French", cards: []))
        }
    }
    .environmentObject(store)
}
