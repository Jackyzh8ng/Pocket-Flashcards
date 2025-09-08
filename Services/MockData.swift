//
//  MockData.swift
//  Pocket Flashcards
//
//  Created by Jacky Zheng on 2025-09-03.
//

import Foundation

enum MockData {
    static let frenchDeckId = UUID()
    static let mathDeckId = UUID()

    static let frenchDeck = Deck(
        id: frenchDeckId,
        title: "French – Subjonctif",
        cards: [
            Card(frontText: "être — je", backText: "je sois", deckId: frenchDeckId),
            Card(frontText: "aller — nous", backText: "nous allions", deckId: frenchDeckId),
            Card(frontText: "faire — il/elle", backText: "qu'il/elle fasse", deckId: frenchDeckId)
        ]
    )

    static let mathDeck = Deck(
        id: mathDeckId,
        title: "Calc – Derivatives",
        cards: [
            Card(frontText: "d/dx (x²)", backText: "2x", deckId: mathDeckId),
            Card(frontText: "d/dx (sin x)", backText: "cos x", deckId: mathDeckId),
            Card(frontText: "d/dx (e^x)", backText: "e^x", deckId: mathDeckId)
        ]
    )

    static let allDecks: [Deck] = [frenchDeck, mathDeck]
}
