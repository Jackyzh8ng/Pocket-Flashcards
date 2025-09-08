import SwiftUI

struct QuizFinishView: View {
    let deckId: UUID
    let correct: Int
    let wrong: Int
    let total: Int
    let elapsedSeconds: Int
    var onDone: (() -> Void)? = nil

    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    private var scorePct: Double { total > 0 ? Double(correct) / Double(total) : 0 }

    var body: some View {
        VStack(spacing: 24) {
            Text("Quiz Complete 🎉").font(.title2).bold()

            VStack(alignment: .leading, spacing: 8) {
                Label("\(correct) Correct", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                Label("\(wrong) Wrong", systemImage: "xmark.circle.fill").foregroundStyle(.red)
                Label("Time \(formatTime(elapsedSeconds))", systemImage: "clock").foregroundStyle(.secondary)
                Label("\(Int((scorePct * 100).rounded()))% Score", systemImage: "percent").foregroundStyle(.secondary)
            }
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)

            ProgressView(value: scorePct).progressViewStyle(.linear).tint(.green)

            Button {
                // Save result, then pop results and quiz
                store.recordQuizResult(deckId: deckId, correct: correct, wrong: wrong, total: total, elapsedSeconds: elapsedSeconds)
                dismiss()
                DispatchQueue.main.async { onDone?() }
            } label: {
                Label("Done", systemImage: "checkmark")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatTime(_ s: Int) -> String {
        String(format: "%02d:%02d", s/60, s%60)
    }
}

#Preview {
    let store = DataStore(useMock: true, autosave: false)
    return NavigationStack {
        QuizFinishView(deckId: UUID(), correct: 7, wrong: 3, total: 10, elapsedSeconds: 95)
            .environmentObject(store)
    }
}
