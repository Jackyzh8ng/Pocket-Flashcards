import SwiftUI

struct ProgressViewScreen: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        List {
            // Overall
            Section("Overview") {
                let sessions = store.quizHistory.count
                let overallAccuracy = store.quizHistory.isEmpty
                    ? 0
                    : store.quizHistory.map(\.accuracy).reduce(0,+) / Double(store.quizHistory.count)

                LabeledContent("Sessions", value: "\(sessions)")
                LabeledContent("Overall Accuracy", value: "\(Int((overallAccuracy*100).rounded()))%")
            }

            // Recent sessions
            if !store.quizHistory.isEmpty {
                Section("Recent Sessions") {
                    ForEach(store.quizHistory.prefix(10)) { r in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(deckTitle(for: r.deckId))
                                .font(.headline)
                            HStack(spacing: 12) {
                                Text("\(r.correct)/\(r.total) (\(Int((r.accuracy*100).rounded()))%)")
                                Text("• \(formatTime(r.elapsedSeconds))")
                                Text("• \(formatDate(r.date))")
                            }
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        }
                    }
                }
            }

            // By deck
            Section("By Deck") {
                ForEach(store.decks) { deck in
                    let s = store.statsForDeck(deck.id)
                    HStack {
                        VStack(alignment: .leading) {
                            Text(deck.title).font(.headline)
                            Text("\(s.sessions) sessions")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(Int((s.avgAccuracy*100).rounded()))% avg")
                            .font(.headline.monospacedDigit())
                    }
                }
            }
        }
        .navigationTitle("Progress")
    }

    private func deckTitle(for id: UUID) -> String {
        store.decks.first(where: { $0.id == id })?.title ?? "Unknown Deck"
    }

    private func formatTime(_ s: Int) -> String {
        String(format: "%02d:%02d", s/60, s%60)
    }

    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: d)
    }
}

#Preview {
    let store = DataStore(useMock: true, autosave: false)
    return NavigationStack { ProgressViewScreen() }
        .environmentObject(store)
}
