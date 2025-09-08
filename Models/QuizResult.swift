//
//  QuizResult.swift
//  Pocket Flashcards
//
//  Created by Jacky Zheng on 2025-09-08.
//

import Foundation

struct QuizResult: Identifiable, Codable {
    let id: UUID
    let deckId: UUID
    let date: Date
    let correct: Int
    let wrong: Int
    let total: Int
    let elapsedSeconds: Int

    var accuracy: Double { total > 0 ? Double(correct) / Double(total) : 0 }
}
