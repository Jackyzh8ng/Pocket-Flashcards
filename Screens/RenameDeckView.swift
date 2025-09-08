//
//  RenameDeckView.swift
//  Pocket Flashcards
//
//  Created by Jacky Zheng on 2025-09-07.
//

import SwiftUI

struct RenameDeckView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    let deckId: UUID
    @State private var title: String

    init(deck: Deck) {
        deckId = deck.id
        _title = State(initialValue: deck.title)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Deck title", text: $title)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("Rename Deck")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.renameDeck(deckId, to: title.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}



