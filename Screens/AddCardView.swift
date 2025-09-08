import SwiftUI

struct AddCardView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    let deckId: UUID
    @State private var front = ""
    @State private var back  = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Front") { TextField("Question / prompt", text: $front, axis: .vertical) }
                Section("Back")  { TextField("Answer", text: $back,  axis: .vertical) }
            }
            .navigationTitle("New Card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addCard(
                            front: front.trimmingCharacters(in: .whitespacesAndNewlines),
                            back:  back .trimmingCharacters(in: .whitespacesAndNewlines),
                            to: deckId
                        )
                        dismiss()
                    }
                    .disabled(front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              back .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    let store = DataStore(useMock: true)
    let deckId = store.decks.first?.id ?? UUID()
    return NavigationStack {
        AddCardView(deckId: deckId)
    }
    .environmentObject(store)
}
//
//  AddCardView.swift
//  Pocket Flashcards
//
//  Created by Jacky Zheng on 2025-09-06.
//

