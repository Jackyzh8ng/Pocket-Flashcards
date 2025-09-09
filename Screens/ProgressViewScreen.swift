import SwiftUI

struct ProgressViewScreen: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        List {
            // BY DECK: mastery and rollups
            Section("By Deck") {
                ForEach(store.decks) { deck in
                    let s = statsForDeck(deck.id)
                    let mastery = masteryForDeck(deck.id)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(deck.title).font(.headline)
                            Spacer()
                            Text("\(Int((mastery * 100).rounded()))% mastered")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: mastery)
                            .tint(masteryTint(mastery))
                            .animation(.easeInOut(duration: 0.25), value: mastery)

                        HStack(spacing: 16) {
                            Label("\(s.sessions) sessions", systemImage: "list.number")
                                .foregroundStyle(.secondary)
                            Label("Avg \(percent(s.avgAccuracy))", systemImage: "chart.bar")
                                .foregroundStyle(.secondary)
                            Label("Best \(percent(s.bestAccuracy))", systemImage: "star.fill")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            }

            // PAST QUIZ RESULTS
            if !store.quizHistory.isEmpty {
                Section("Past Quiz Results") {
                    ForEach(store.quizHistory) { r in
                        let title = store.decks.first(where: { $0.id == r.deckId })?.title ?? "Unknown Deck"
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(title).font(.headline)
                                HStack(spacing: 10) {
                                    Text("\(r.correct)/\(r.total) • \(percent(r.accuracy))")
                                        .font(.subheadline.monospacedDigit())
                                    Text("• \(formatTime(r.elapsedSeconds))")
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                    Text("• \(grade(for: r.accuracy))")
                                        .font(.subheadline)
                                        .foregroundStyle(gradeColor(for: r.accuracy))
                                }
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(formatDate(r.date))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            } else {
                Section("Past Quiz Results") {
                    Text("No quiz results yet. Take a quiz to see your progress here.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Progress")
    }

    // MARK: - Deck stats & mastery

    /// Returns session count, average accuracy, best accuracy for a deck.
    private func statsForDeck(_ deckId: UUID) -> (sessions: Int, avgAccuracy: Double, bestAccuracy: Double) {
        let results = store.quizHistory.filter { $0.deckId == deckId }
        guard !results.isEmpty else { return (0, 0, 0) }
        let avg = results.map(\.accuracy).reduce(0, +) / Double(results.count)
        let best = results.map(\.accuracy).max() ?? 0
        return (results.count, avg, best)
    }

    /// Heuristic "mastery": weighted average of the last up to 10 session accuracies for the deck.
    /// Newer sessions count more (weights 10…1). Returns 0…1.
    private func masteryForDeck(_ deckId: UUID) -> Double {
        let all = store.quizHistory.filter { $0.deckId == deckId }
        guard !all.isEmpty else { return 0 }
        // quizHistory should be newest-first (insert at 0). Use up to the last 10.
        let recent = Array(all.prefix(10))
        let n = recent.count
        let weights = (1...n).reversed().map { Double($0) } // 10,9,... or n,...,1
        let weighted = zip(recent.map(\.accuracy), weights).map(*).reduce(0, +)
        let totalWeight = weights.reduce(0, +)
        return max(0, min(1, weighted / totalWeight))
    }

    // MARK: - Formatting

    private func percent(_ x: Double) -> String {
        "\(Int((x * 100).rounded()))%"
    }

    private func formatTime(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }

    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: d)
    }

    private func grade(for accuracy: Double) -> String {
        switch accuracy {
        case 0.90...1.0: return "A"
        case 0.80..<0.90: return "B"
        case 0.70..<0.80: return "C"
        case 0.60..<0.70: return "D"
        default: return "F"
        }
    }

    private func gradeColor(for accuracy: Double) -> Color {
        switch accuracy {
        case 0.90...1.0: return .green
        case 0.80..<0.90: return .green
        case 0.70..<0.80: return .orange
        case 0.60..<0.70: return .orange
        default: return .red
        }
    }

    private func masteryTint(_ m: Double) -> Color {
        switch m {
        case 0.85...1: return .green
        case 0.6..<0.85: return .orange
        default: return .red
        }
    }
}

#Preview {
    let store = DataStore(useMock: true)
    return NavigationStack {
        ProgressViewScreen()
            .environmentObject(store)
    }
}
