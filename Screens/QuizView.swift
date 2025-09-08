import SwiftUI

struct QuizView: View {
    let deck: Deck

    @Environment(\.dismiss) private var dismissQuiz
    @Environment(\.dismiss) private var dismiss


    @State private var index = 0
    @State private var correct = 0
    @State private var wrong = 0
    @State private var showBack = false
    @State private var finished = false

    // Quit confirmation
    @State private var confirmQuit = false

    // ⏱️ Elapsed time
    @State private var startDate = Date()
    @State private var elapsedSeconds = 0
    @State private var ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var cards: [Card] { deck.cards }
    private var total: Int { cards.count }
    private var card: Card? {
        guard index < total else { return nil }
        return cards[index]
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header: title, progress, elapsed time
            HStack(alignment: .firstTextBaseline) {
                Text(deck.title).font(.headline)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(correct + wrong)/\(total)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Text(formatTime(elapsedSeconds))
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            if total == 0 {
                ContentUnavailableView("No cards", systemImage: "rectangle.on.rectangle.slash")
            } else if let card {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .frame(height: 260)
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
                .padding(.horizontal)
                .rotation3DEffect(.degrees(showBack ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .animation(.easeInOut(duration: 0.25), value: showBack)
                .onTapGesture { showBack.toggle() }

                // Big centered buttons
                HStack(spacing: 20) {
                    Button { markCorrect() } label: {
                        Label("Correct", systemImage: "checkmark")
                            .font(.title3)
                            .frame(minWidth: 140, minHeight: 56)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .buttonBorderShape(.capsule)

                    Button { markWrong() } label: {
                        Label("Wrong", systemImage: "xmark")
                            .font(.title3)
                            .frame(minWidth: 140, minHeight: 56)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .buttonBorderShape(.capsule)
                }
                .frame(maxWidth: .infinity)
                .controlSize(.large)
                .padding(.top, 8)
            } else {
                // Safety: if we render past last card, trigger finish
                Color.clear
                    .frame(height: 1)
                    .onAppear { finished = true }
            }
        }
        .padding()
        .navigationTitle("Quiz")
        .navigationBarTitleDisplayMode(.inline)

        // Top-bar Quit button
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    confirmQuit = true
                } label: {
                    Label("Quit", systemImage: "xmark.circle")
                }
            }
        }
        .alert("Are you sure you want to quit?",
               isPresented: $confirmQuit) {
            Button("Cancel", role: .cancel) { }
            Button("Quit", role: .destructive) { dismiss() }  // back to DeckDetailView
        } message: {
            Text("Your progress for this quiz will be lost.")
        }

        // ⏱️ Start/reset the timer when the view appears
        .onAppear {
            index = 0; correct = 0; wrong = 0; showBack = false
            startDate = Date()
            elapsedSeconds = 0
        }

        // ⏱️ Tick every second while not finished
        .onReceive(ticker) { _ in
            guard !finished else { return }
            elapsedSeconds = max(0, Int(Date().timeIntervalSince(startDate)))
        }

        // Navigate to results when finished
        .navigationDestination(isPresented: $finished) {
            QuizFinishView(
                correct: correct,
                wrong: wrong,
                total: total,
                elapsedSeconds: elapsedSeconds,
                onDone: { dismissQuiz() }
            )
        }
    }

    // MARK: - Actions

    private func markCorrect() {
        correct += 1
        advance()
    }

    private func markWrong() {
        wrong += 1
        advance()
    }

    private func advance() {
        showBack = false
        index += 1
        if index >= total {
            finished = true
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

#Preview {
    let deckId = UUID()
    let sample = Deck(
        id: deckId, title: "French – Subjonctif",
        cards: [
            Card(frontText: "être — je", backText: "je sois", deckId: deckId),
            Card(frontText: "aller — nous", backText: "nous allions", deckId: deckId),
            Card(frontText: "faire — il/elle", backText: "qu’il/elle fasse", deckId: deckId)
        ]
    )
    return NavigationStack { QuizView(deck: sample) }
}
