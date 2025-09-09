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

    private var liveDeck: Deck? { store.decks.first(where: { $0.id == deck.id }) }
    private var isFiltering: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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
                VStack(spacing: 12) {
                    // Non-scrolling header
                    HeaderBlock(
                        cardCount: d.cardCount,
                        markedCount: store.markedCount(d.id),
                        onShuffleStudy: { store.shuffleDeck(d.id); startStudy = true },
                        onStudyMarked: { startStudyMarked = true }
                    )
                    .padding(.horizontal)

                    // Non-scrolling Add / Bulk Add row
                    AddBulkRow(
                        onAdd: { showAddCard = true },
                        onBulkAdd: { showBulkAdd = true }
                    )
                    .padding(.horizontal)

                    // Scroll-in-place list, styled like the old one
                    CardsList(
                        deck: d,
                        cards: filteredCards(for: d),
                        canMove: !isFiltering,
                        onEdit: { editingCard = $0 },
                        onDelete: { cardId in store.deleteCard(cardId, from: d.id) },
                        onMove: { src, dst in store.moveCards(in: d.id, from: src, to: dst) }
                    )
                    .frame(maxHeight: .infinity) // ← only this area scrolls
                }
                .padding(.top, 8)
                .background(Color(.systemGroupedBackground))
                .navigationTitle(d.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { renamingDeck = true } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                    }
                }
                // Bottom bar: Study + Quiz
                .safeAreaInset(edge: .bottom) {
                    BottomBar(
                        cardCount: d.cardCount,
                        onStudy: { startStudy = true },
                        onQuiz: { store.shuffleDeck(d.id); startQuiz = true }
                    )
                }
                // Sheets / navigation
                .sheet(isPresented: $showAddCard) { EditCardView(deck: d).environmentObject(store) }
                .sheet(item: $editingCard) { card in EditCardView(deck: d, card: card).environmentObject(store) }
                .sheet(isPresented: $renamingDeck) { RenameDeckView(deck: d).environmentObject(store) }
                .sheet(isPresented: $showBulkAdd) { BulkAddCardsView(deckId: d.id).environmentObject(store) }

                .navigationDestination(isPresented: $startStudy) {
                    if let fresh = store.decks.first(where: { $0.id == deck.id }) {
                        StudyView(deck: fresh).environmentObject(store)
                    } else { ContentUnavailableView("Deck not found", systemImage: "exclamationmark.triangle") }
                }
                .navigationDestination(isPresented: $startQuiz) {
                    if let fresh = store.decks.first(where: { $0.id == deck.id }) {
                        QuizView(deck: fresh)
                            .navigationBarBackButtonHidden(true)
                            .environmentObject(store)
                    } else { ContentUnavailableView("Deck not found", systemImage: "exclamationmark.triangle") }
                }
                .navigationDestination(isPresented: $startStudyMarked) {
                    if let fresh = store.decks.first(where: { $0.id == deck.id }) {
                        let onlyMarked = fresh.cards.filter { $0.isMarked }
                        StudyView(deck: fresh, cardsOverride: onlyMarked).environmentObject(store)
                    } else { ContentUnavailableView("Deck not found", systemImage: "exclamationmark.triangle") }
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

// MARK: - Non-scrolling header blocks

private struct HeaderBlock: View {
    let cardCount: Int
    let markedCount: Int
    let onShuffleStudy: () -> Void
    let onStudyMarked: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(cardCount) cards")
                .foregroundStyle(.secondary)

            HStack {
                Button(action: onShuffleStudy) {
                    Label("Shuffle & Study", systemImage: "shuffle")
                }
                .buttonStyle(.bordered)
                .disabled(cardCount == 0)

                Button(action: onStudyMarked) {
                    Label("Study Marked (\(markedCount))", systemImage: "bookmark")
                }
                .buttonStyle(.bordered)
                .disabled(markedCount == 0)
            }
        }
    }
}

private struct AddBulkRow: View {
    let onAdd: () -> Void
    let onBulkAdd: () -> Void

    var body: some View {
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

// MARK: - Scroll-in-place card list (old look)

private struct CardsList: View {
    let deck: Deck
    let cards: [Card]
    let canMove: Bool
    let onEdit: (Card) -> Void
    let onDelete: (UUID) -> Void
    let onMove: (IndexSet, Int) -> Void

    var body: some View {
        List {
            Section {
                // Inline Edit row — sits directly above first card
                HStack {
                    Label("Edit Cards", systemImage: "square.and.pencil")
                    Spacer()
                    EditButton()                  // stays enabled during search
                }
                .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))

                // Card rows
                if canMove {
                    ForEach(cards) { card in cardRow(card) }
                        .onDelete(perform: delete)
                        .onMove(perform: onMove)
                } else {
                    ForEach(cards) { card in cardRow(card) }
                        .onDelete(perform: delete)
                        .moveDisabled(true)      // allow delete while searching; disable reordering
                }
            }
        }
        .listStyle(.plain)                        // ← old, clean look
        .scrollContentBackground(.hidden)         // use parent background
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private func cardRow(_ card: Card) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.frontText).bold()
            Text(card.backText).foregroundStyle(.secondary)
        }
        .listRowInsets(.init(top: 10, leading: 16, bottom: 10, trailing: 16))
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

// MARK: - Bottom bar

private struct BottomBar: View {
    let cardCount: Int
    let onStudy: () -> Void
    let onQuiz: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Button(action: onStudy) {
                    Label("Study \(cardCount)", systemImage: "book.fill")
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .disabled(cardCount == 0)

                Button(action: onQuiz) {
                    Label("Quiz", systemImage: "exclamationmark.triangle.fill")
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(cardCount == 0)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)
        }
        .background(.bar)
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
