//
//  Deck.swift
//  Pocket Flashcards
//
//  Created by Jacky Zheng on 2025-09-03.
//

import Foundation

struct Deck: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var title: String
    var cards: [Card] = []
    var cardCount: Int{ cards.count}
}

