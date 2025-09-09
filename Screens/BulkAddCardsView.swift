//
//  BulkAddCardsView.swift
//  Pocket Flashcards
//
//  Created by Jacky Zheng on 2025-09-08.
//

import SwiftUI

struct BulkAddCardsView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    let deckId: UUID

    @State private var text: String = ""
    @FocusState private var focused: Bool

    private var parsedPairs: [(String, String)] { parse(text) }
    private var count: Int { parsedPairs.count }

    var body: some View {
        NavigationStack {
            Form {
                Section("Paste or type cards") {
                    TextEditor(text: $text)
                        .font(.body.monospaced())
                        .frame(minHeight: 220)
                        .focused($focused)
                        .overlay(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("One card per line. Example:\nbonjour - hello\nau revoir - goodbye\n")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section("Preview") {
                    if count == 0 {
                        Text("Use separators like “-”, “|”, comma, semicolon, or tab.\nExample:  front - back")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(count) cards ready").foregroundStyle(.secondary)
                        ForEach(Array(parsedPairs.prefix(3).enumerated()), id: \.0) { _, pair in
                            HStack {
                                Text(pair.0).bold()
                                Spacer()
                                Text(pair.1).foregroundStyle(.secondary)
                            }
                        }
                        if count > 3 {
                            Text("…and \(count - 3) more")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Bulk Add")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add \(count)") {
                        store.addCards(parsedPairs, to: deckId)
                        dismiss()
                    }
                    .disabled(count == 0)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focused = false }
                }
            }
            .onAppear { focused = true }
        }
    }

    // MARK: - Parsing
    private func parse(_ input: String) -> [(String, String)] {
        var out: [(String, String)] = []
        let lines = input.components(separatedBy: .newlines)

        // Supported separators, in order of preference
        let seps = ["\t", " - ", " — ", " | ", " ; ", ", ", " -", "- ", "-", "|", ";", ",", " —", "— "]

        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            var chosen: (String, String)? = nil
            for sep in seps {
                let parts = line.components(separatedBy: sep)
                if parts.count >= 2 {
                    let front = parts.first!.trimmingCharacters(in: .whitespacesAndNewlines)
                    let back  = parts.dropFirst().joined(separator: sep).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !front.isEmpty, !back.isEmpty {
                        chosen = (front, back)
                        break
                    }
                }
            }
            if let pair = chosen { out.append(pair) }
        }
        return out
    }
}

#Preview {
    let store = DataStore(useMock: true, autosave: false)
    return NavigationStack {
        BulkAddCardsView(deckId: store.decks.first?.id ?? UUID())
            .environmentObject(store)
    }
}
