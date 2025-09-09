//
//  Card.swift
//  Pocket Flashcards
//
//  Created by Jacky Zheng on 2025-09-03.
//
// Card.swift
import Foundation

struct Card: Identifiable, Hashable, Codable {
    let id: UUID
    var frontText: String
    var backText: String
    let deckId: UUID

    // NEW
    var isMarked: Bool = false

    // If you have custom init(s):
    init(
        id: UUID = UUID(),
        frontText: String,
        backText: String,
        deckId: UUID,
        isMarked: Bool = false
    ) {
        self.id = id
        self.frontText = frontText
        self.backText = backText
        self.deckId = deckId
        self.isMarked = isMarked
    }

    // If you already had CodingKeys, add isMarked and default it when missing:
    enum CodingKeys: String, CodingKey { case id, frontText, backText, deckId, isMarked }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decode(UUID.self, forKey: .id)
        frontText = try c.decode(String.self, forKey: .frontText)
        backText  = try c.decode(String.self, forKey: .backText)
        deckId    = try c.decode(UUID.self, forKey: .deckId)
        isMarked  = (try? c.decode(Bool.self, forKey: .isMarked)) ?? false
    }
}

