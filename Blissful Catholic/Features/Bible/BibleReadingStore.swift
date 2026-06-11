//
//  BibleReadingStore.swift
//  Blissful Catholic
//
//  "Where you left off" in the Bible — the last book + chapter opened, so Learn
//  can offer a Continue Reading shortcut. A lightweight UserDefaults pointer,
//  same approach as RosaryProgressStore / PodcastProgressStore (transient UI
//  state, not history).
//

import Foundation

struct BibleReadingProgress: Codable, Hashable {
    let bookCode: String
    let bookName: String
    let chapterCount: Int
    let chapter: Int
    let savedAt: Date

    /// Rebuild the navigation ref so Continue can jump straight to the reader.
    var bookRef: BibleBookRef {
        BibleBookRef(code: bookCode, name: bookName, chapterCount: chapterCount)
    }
}

enum BibleReadingStore {
    private static let key = "bible.lastRead"

    static func save(book: BibleBookRef, chapter: Int) {
        let progress = BibleReadingProgress(
            bookCode: book.code, bookName: book.name,
            chapterCount: book.chapterCount, chapter: chapter, savedAt: .now)
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load() -> BibleReadingProgress? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(BibleReadingProgress.self, from: data)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
