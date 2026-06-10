//
//  BibleRoute.swift
//  Blissful Catholic
//
//  Navigation for the Bible reader, pushed inside the Learn tab's NavigationStack:
//  books → chapters → reader. Backed by the already-bundled WEBCE via BibleService.
//

import Foundation

/// A book plus the metadata navigation needs (name to show, chapter count to
/// build the grid + bound prev/next).
struct BibleBookRef: Hashable {
    let code: String          // USFM code, e.g. "JHN"
    let name: String          // "John"
    let chapterCount: Int
}

enum BibleRoute: Hashable {
    case books
    case chapters(book: BibleBookRef)
    case reader(book: BibleBookRef, chapter: Int)
}
