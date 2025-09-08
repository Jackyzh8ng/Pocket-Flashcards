import SwiftUI

struct QuizFinishView: View {
    let correct: Int
    let wrong: Int
    let total: Int
    let elapsedSeconds: Int
    var onDone: (() -> Void)? = nil   // <-- callback to pop QuizView

    @Environment(\.dismiss) private var dismiss

    private var scorePct: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Quiz Complete 🎉")
                .font(.title2).bold()

            VStack(alignment: .leading, spacing: 8) {
                Label("\(correct) Correct", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Label("\(wrong) Wrong", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Label("Time \(formatTime(elapsedSeconds))", systemImage: "clock")
                    .foregroundStyle(.secondary)
                Label("\(Int((scorePct * 100).rounded()))% Score", systemImage: "percent")
                    .foregroundStyle(.secondary)
            }
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)

            ProgressView(value: scorePct)
                .progressViewStyle(.linear)
                .tint(.green)

            Button {
                // 1) Pop QuizFinishView
                dismiss()
                // 2) Then pop QuizView (back to DeckDetailView)
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

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

#Preview {
    NavigationStack {
        QuizFinishView(correct: 7, wrong: 3, total: 10, elapsedSeconds: 95)
    }
}
