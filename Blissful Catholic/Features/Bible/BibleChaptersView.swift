//
//  BibleChaptersView.swift
//  Blissful Catholic
//
//  A grid of chapter numbers for one book. Tapping a chapter pushes the reader.
//

import SwiftUI

struct BibleChaptersView: View {
    let book: BibleBookRef

    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                LumenDeepHeader(eyebrow: "Read", title: book.name) { dismiss() }

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(1...max(1, book.chapterCount), id: \.self) { chapter in
                            NavigationLink(value: BibleRoute.reader(book: book, chapter: chapter)) {
                                chapterCell(chapter)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func chapterCell(_ chapter: Int) -> some View {
        Text("\(chapter)")
            .font(LumenType.display(18))
            .foregroundStyle(t.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(t.surface, in: .rect(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(t.rule, lineWidth: 0.5))
    }
}
