//
//  StatsPersistence.swift
//  Pocket Flashcards
//
//  Created by Jacky Zheng on 2025-09-08.
//

import Foundation

enum StatsPersistence {
    private static let fileName = "quiz_history.json"

    static var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(fileName)
    }

    static func load() throws -> [QuizResult] {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([QuizResult].self, from: data)
    }

    static func save(_ results: [QuizResult]) throws {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try enc.encode(results)
        try data.write(to: fileURL, options: .atomic)
    }
}
