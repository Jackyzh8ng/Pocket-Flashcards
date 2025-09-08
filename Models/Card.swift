//
//  Card.swift
//  Pocket Flashcards
//
//  Created by Jacky Zheng on 2025-09-03.
//
import Foundation

struct Card: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var frontText: String
    var backText: String
    var deckId: UUID = UUID()
}
