import SwiftUI

struct StudyView: View {
    let deck: Deck
    let cardsOverride: [Card]?

    init(deck: Deck, cardsOverride: [Card]? = nil) {
        self.deck = deck
        self.cardsOverride = cardsOverride
    }

    @State private var index = 0
    @State private var showBack = false
    @State private var rightCount = 0
    @State private var wrongCount = 0

    private var cards: [Card] { cardsOverride ?? deck.cards }
    private var total: Int { cards.count }
    private var card: Card? { cards.indices.contains(index) ? cards[index] : nil }

    // 1-based position for UI (shows 1/total on first card)
    private var position: Int { total == 0 ? 0 : (index % total) + 1 }

    var body: some View {
        VStack(spacing: 24) {
            if let card {
                Text(deck.title).font(.headline)

                // Counter + progress (1-based)
                HStack {
                    Text("\(position)/\(total)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: Double(position), total: Double(max(total, 1)))
                    .tint(.green)

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .frame(height: 240)
                        .shadow(radius: 6)

                    // FRONT
                    Text(card.frontText)
                        .font(.title2).fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .opacity(showBack ? 0 : 1)

                    // BACK (counter-rotated)
                    Text(card.backText)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .opacity(showBack ? 1 : 0)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                }
                .padding()
                .rotation3DEffect(.degrees(showBack ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .animation(.easeInOut(duration: 0.25), value: showBack)
                .onTapGesture { showBack.toggle() }

                HStack {
                    Button { backCard() } label: { Label("Back", systemImage: "arrow.uturn.left") }
                    Spacer()
                    Button { nextCard(asSkip: true) } label: { Label("Skip", systemImage: "arrow.uturn.right") }
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
            } else {
                ContentUnavailableView("No cards", systemImage: "rectangle.on.rectangle.slash")
            }

            // Scoreboard
            HStack(spacing: 24) {
                Label("\(rightCount)", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                Label("\(wrongCount)", systemImage: "xmark.circle.fill").foregroundStyle(.red)
            }
            .font(.headline)

            // Big centered buttons
            HStack(spacing: 20) {
                Button { markCorrect() } label: {
                    Label("Correct", systemImage: "checkmark")
                        .font(.title3)
                        .frame(minWidth: 140, minHeight: 56)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .buttonBorderShape(.capsule)

                Button { markWrong() } label: {
                    Label("Wrong", systemImage: "xmark")
                        .font(.title3)
                        .frame(minWidth: 140, minHeight: 56)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .buttonBorderShape(.capsule)
            }
            .frame(maxWidth: .infinity)
            .controlSize(.large)
            .padding(.top, 8)
        }
        .padding()
        .navigationTitle("Study")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            index = 0
            showBack = false
            rightCount = 0
            wrongCount = 0
        }
    }

    // MARK: - Actions

    private func nextCard(asSkip: Bool = false) {
        showBack = false
        guard !cards.isEmpty else { return }
        if asSkip { wrongCount += 1 }       // keep your “Skip counts as wrong” behavior
        index = (index + 1) % cards.count   // wraps; position will show 1 again after wrap
    }

    private func backCard() {
        showBack = false
        guard !cards.isEmpty else { return }
        if index == 0 {
            index = cards.count - 1         // wrap backwards
        } else {
            index -= 1
        }
    }

    private func markCorrect() {
        rightCount += 1
        nextCard()
    }

    private func markWrong() {
        wrongCount += 1
        nextCard()
    }
}

#Preview {
    let deckId = UUID()
    let sampleDeck = Deck(
        id: deckId,
        title: "French – Subjonctif",
        cards: [
            Card(frontText: "être — je", backText: "je sois", deckId: deckId),
            Card(frontText: "aller — nous", backText: "nous allions", deckId: deckId),
            Card(frontText: "faire — il/elle", backText: "qu’il/elle fasse", deckId: deckId)
        ]
    )
    return NavigationStack { StudyView(deck: sampleDeck) }
}
