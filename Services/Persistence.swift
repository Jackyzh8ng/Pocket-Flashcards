//
//  Persistence.swift
//  Pocket Flashcards
//
//  Created by Jacky Zheng on 2025-09-07.
//

import Foundation

enum Persistence {
    private static let fileName = "decks.json"
    
    static var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(fileName)
    }
    
    static func load () throws -> [Deck]{
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else {return []}
        let data = try Data (contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([Deck].self, from: data)
        
    }
    
    static func save(_ decks: [Deck]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(decks)
        try data.write(to: fileURL, options: .atomic)
    }
}
