//
//  BibleChapterReaderView.swift
//  Blissful Catholic
//
//  Reads one chapter of the bundled WEBCE. Tap a verse to select it (tap more to
//  build a selection); a docked bar then lets you ask the AI companion to explain
//  the passage — the answer to the original "I don't understand this verse" need.
//  Prev/next move between chapters in place.
//

import SwiftUI

struct BibleChapterReaderView: View {
    let book: BibleBookRef

    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal
    @Environment(\.dismiss) private var dismiss

    @State private var chapter: Int
    @State private var verses: [BibleVerse] = []
    @State private var selected: Set<Int> = []
    @State private var showExplain = false

    init(book: BibleBookRef, chapter: Int) {
        self.book = book
        _chapter = State(initialValue: chapter)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            t.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                LumenDeepHeader(eyebrow: book.name, title: "Chapter \(chapter)") { dismiss() }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            if verses.isEmpty {
                                ProgressView().tint(pal.accent).padding(.top, 60)
                            } else {
                                ForEach(verses) { verse in
                                    verseRow(verse).id(verse.verse)
                                }
                                chapterNav.padding(.top, 26)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                        .padding(.bottom, selected.isEmpty ? 120 : 190)
                    }
                    .onChange(of: chapter) { _, _ in
                        proxy.scrollTo(verses.first?.verse, anchor: .top)
                    }
                }
            }

            if !selected.isEmpty { selectionBar }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task(id: chapter) { await load() }
        .sheet(isPresented: $showExplain) {
            AIReflectionView(
                feature: "scripture_explain",
                prompt: explainPrompt,
                title: referenceLabel,
                reason: "Sign in to get help understanding this passage."
            )
        }
    }

    // MARK: Verse row

    private func verseRow(_ verse: BibleVerse) -> some View {
        let isSelected = selected.contains(verse.verse)
        return Button { toggle(verse.verse) } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(verse.verse)")
                    .font(LumenType.ui(10, weight: .semibold))
                    .foregroundStyle(pal.accent)
                    .frame(minWidth: 18, alignment: .trailing)
                Text(verse.text)
                    .font(LumenType.serif(17))
                    .foregroundStyle(t.ink)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isSelected ? pal.accent.opacity(0.14) : .clear, in: .rect(cornerRadius: 8))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    // MARK: Selection bar

    private var selectionBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(referenceLabel)
                    .font(LumenType.ui(12, weight: .semibold))
                    .foregroundStyle(t.ink)
                Text("\(selected.count) verse\(selected.count == 1 ? "" : "s") selected")
                    .font(LumenType.ui(10))
                    .foregroundStyle(t.inkSoft)
            }
            Spacer(minLength: 0)

            Button { selected.removeAll() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13))
                    .foregroundStyle(t.inkMid)
                    .frame(width: 38, height: 38)
                    .background(t.surface3, in: .circle)
            }
            .buttonStyle(.plain)

            Button { showExplain = true } label: {
                Label("Explain", systemImage: "sparkles")
                    .font(LumenType.ui(13, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 44)
                    .background(pal.accent, in: .capsule)
                    .shadow(color: pal.accent.opacity(0.4), radius: 10, y: 5)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: .rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(t.rule, lineWidth: 0.5))
        .padding(.horizontal, 14)
        .padding(.bottom, 96)   // clear the floating tab bar
    }

    // MARK: Chapter nav

    private var chapterNav: some View {
        HStack {
            if chapter > 1 {
                navButton("Chapter \(chapter - 1)", "chevron.left", leading: true) {
                    changeChapter(to: chapter - 1)
                }
            }
            Spacer()
            if chapter < book.chapterCount {
                navButton("Chapter \(chapter + 1)", "chevron.right", leading: false) {
                    changeChapter(to: chapter + 1)
                }
            }
        }
    }

    private func navButton(_ title: String, _ symbol: String, leading: Bool,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if leading { Image(systemName: symbol) }
                Text(title)
                if !leading { Image(systemName: symbol) }
            }
            .font(LumenType.ui(12, weight: .medium))
            .foregroundStyle(pal.accent)
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(t.surface, in: .capsule)
            .overlay(Capsule().strokeBorder(t.rule, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: Logic

    private func toggle(_ verse: Int) {
        if selected.contains(verse) { selected.remove(verse) } else { selected.insert(verse) }
    }

    private func changeChapter(to newChapter: Int) {
        selected.removeAll()
        chapter = newChapter   // .task(id: chapter) reloads
    }

    private func load() async {
        verses = await BibleService.shared.chapter(book: book.code, chapter: chapter)
    }

    /// "John 3:16", "John 3:16–18", or "John 3:16, 18" — collapses runs.
    private var referenceLabel: String {
        let nums = selected.sorted()
        guard !nums.isEmpty else { return "\(book.name) \(chapter)" }
        return "\(book.name) \(chapter):\(rangeString(nums))"
    }

    private func rangeString(_ nums: [Int]) -> String {
        var parts: [String] = []
        var runStart = nums[0], prev = nums[0]
        for n in nums.dropFirst() {
            if n == prev + 1 { prev = n; continue }
            parts.append(runStart == prev ? "\(runStart)" : "\(runStart)–\(prev)")
            runStart = n; prev = n
        }
        parts.append(runStart == prev ? "\(runStart)" : "\(runStart)–\(prev)")
        return parts.joined(separator: ", ")
    }

    private var explainPrompt: String {
        let passage = verses
            .filter { selected.contains($0.verse) }
            .map { "\($0.verse) \($0.text)" }
            .joined(separator: " ")
        return """
        I'm reading \(referenceLabel) and I'm not sure I understand it. Here is the passage:

        \(passage)

        Please help me understand what it means — explain it clearly and faithfully, \
        in keeping with Catholic teaching and drawing on Scripture and the Church's \
        tradition. Keep it warm and accessible.
        """
    }
}
