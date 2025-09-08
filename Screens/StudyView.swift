import SwiftUI

struct StudyView: View {
    let deck: Deck
    let cardsOverride: [Card]?

    // Allow calling either: StudyView(deck: d) or StudyView(deck: d, cardsOverride: d.cards.shuffled())
    init(deck: Deck, cardsOverride: [Card]? = nil) {
        self.deck = deck
        self.cardsOverride = cardsOverride
    }

    @State private var index = 0
    @State private var showBack = false
    @State private var rightCount = 0
    @State private var wrongCount = 0
    @State private var attempted  = 0
    private var total: Int { cards.count }



    private var cards: [Card] { cardsOverride ?? deck.cards }
    private var card: Card? { cards.indices.contains(index) ? cards[index] : nil }

    var body: some View {

        VStack(spacing: 24) {
            if let card {
                Text(deck.title)
                    .font(.headline)
                HStack {
                    Text("\(min(attempted, total))/\(total)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: Double(min(attempted, total)), total: Double(max(total, 1)))
                    .tint(.green)


                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .frame(height: 240)
                        .shadow(radius: 6)

                    // FRONT
                    Text(card.frontText)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .opacity(showBack ? 0 : 1)

                    // BACK (counter-rotated so it isn’t mirrored when flipped)
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
                    Button { nextCard() } label: { Label("Back", systemImage: "arrow.uturn.left") }
                    Spacer()
                    Button { nextCard() } label: { Label("Skip", systemImage: "arrow.uturn.right") }
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
            } else {
                ContentUnavailableView("No cards", systemImage: "rectangle.on.rectangle.slash")
            }
            
            HStack(spacing: 24) {
                Label("\(rightCount)", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                Label("\(wrongCount)", systemImage: "xmark.circle.fill").foregroundStyle(.red)
            }
            .font(.headline)

            HStack(spacing: 20) {
                Button {
                    markCorrect()
                } label: {
                    Label("Correct", systemImage: "checkmark")
                        .font(.title3)                    // bigger text
                        .frame(minWidth: 140, minHeight: 56)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderedProminent)          // bold style
                .tint(.green)
                .buttonBorderShape(.capsule)              // rounded pill

                Button {
                    markWrong()
                } label: {
                    Label("Wrong", systemImage: "xmark")
                        .font(.title3)
                        .frame(minWidth: 140, minHeight: 56)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .buttonBorderShape(.capsule)
            }
            .frame(maxWidth: .infinity)                   // center the group
            .controlSize(.large)                          // bump control size
            .padding(.top, 8)

            // .disabled(!showBack) // ← optional: require flip before answering

        }
        .padding()
        .navigationTitle("Study")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Reset session state whenever StudyView appears
            index = 0
            showBack = false
        }
    }

    private func nextCard() {
        showBack = false
        wrongCount += 1
        attempted += 1
        if !cards.isEmpty { index = (index + 1) % cards.count }
    }
    
    private func markCorrect() {
        rightCount += 1
        advanceAfterAnswer()
    }

    private func markWrong() {
        wrongCount += 1
        advanceAfterAnswer()
    }

    private func advanceAfterAnswer() {
        showBack = false
        attempted += 1
        if !cards.isEmpty {
            index = (index + 1) % cards.count
        }
    }
    
    

}

#Preview {
    // Quick preview with sample data
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

    return NavigationStack {
        StudyView(deck: sampleDeck)
    }
}
