//
//  BibleBooksView.swift
//  Blissful Catholic
//
//  The Bible's table of contents — 73 books split into Old / New Testament.
//  Tapping a book pushes its chapter grid.
//

import SwiftUI

struct BibleBooksView: View {
    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal
    @Environment(\.dismiss) private var dismiss

    @State private var oldTestament: [BibleBookRef] = []
    @State private var newTestament: [BibleBookRef] = []

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                LumenDeepHeader(eyebrow: "Read", title: "Holy Bible") { dismiss() }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        section("Old Testament", oldTestament)
                        section("New Testament", newTestament)
                    }
                    .padding(.bottom, 120)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await load() }
    }

    private func section(_ title: String, _ books: [BibleBookRef]) -> some View {
        Group {
            if !books.isEmpty {
                Eyebrow(text: title, color: pal.accent)
                    .padding(.horizontal, 24)
                    .padding(.top, 22)
                    .padding(.bottom, 8)

                ForEach(books, id: \.code) { book in
                    NavigationLink(value: BibleRoute.chapters(book: book)) {
                        bookRow(book)
                    }
                    .buttonStyle(.plain)
                    Rectangle().fill(t.ruleSoft).frame(height: 0.5).padding(.leading, 24)
                }
            }
        }
    }

    private func bookRow(_ book: BibleBookRef) -> some View {
        HStack {
            Text(book.name)
                .font(LumenType.serif(16))
                .foregroundStyle(t.ink)
            Spacer()
            Text("\(book.chapterCount) ch")
                .font(LumenType.ui(11))
                .foregroundStyle(t.inkSoft)
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(t.inkSoft)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 13)
        .contentShape(.rect)
    }

    private func load() async {
        let all = await BibleService.shared.books()
            .map { BibleBookRef(code: $0.code, name: $0.name, chapterCount: $0.chapterCount) }
        // WEBCE is in canonical order; the New Testament begins at Matthew.
        if let matthew = all.firstIndex(where: { $0.code == "MAT" }) {
            oldTestament = Array(all[..<matthew])
            newTestament = Array(all[matthew...])
        } else {
            oldTestament = all
        }
    }
}
