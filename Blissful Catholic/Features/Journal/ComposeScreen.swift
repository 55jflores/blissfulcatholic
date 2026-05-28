//
//  ComposeScreen.swift
//  Blissful Catholic
//
//  The journal writing surface — ruled paper with a red margin line. Presented
//  full-screen (the tab bar steps aside to give the writing room). Phase 1 keeps
//  the text in memory; Phase 2 persists entries to SwiftData.
//

import SwiftUI
import SwiftData

struct ComposeScreen: View {
    /// When set, we're editing an existing entry rather than composing a new one.
    var entry: JournalEntry? = nil

    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var text = ""
    @State private var activeTag = 0
    @State private var loaded = false
    @FocusState private var focused: Bool

    private let tags = ["Examen", "Gratitude", "Intention", "Mass", "Confession prep"]

    var body: some View {
        VStack(spacing: 0) {
            LumenDeepHeader(eyebrow: entry == nil ? "New Entry" : "Edit Entry",
                            title: dateTitle, onBack: { dismiss() }) {
                Button { save() } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(pal.accent, in: .circle)
                }
                .buttonStyle(.plain)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(text: "Tonight's Prompt · Examen", color: pal.accent)
                        Text("Where did you sense God's presence today, even briefly?")
                            .font(LumenType.display(22).italic())
                            .foregroundStyle(t.ink)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 14)

                    paper
                        .padding(.horizontal, 16)

                    tagRow
                        .padding(.horizontal, 24)
                        .padding(.top, 18)
                        .padding(.bottom, 40)
                }
            }
        }
        .background(t.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: loadOnce)
    }

    private func loadOnce() {
        if !loaded, let entry {
            text = entry.content
            activeTag = tags.firstIndex(of: entry.tag) ?? 0
        }
        loaded = true
        focused = true
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let entry {
            entry.content = text
            entry.tag = tags[activeTag]
        } else if !trimmed.isEmpty {
            let e = JournalEntry()
            e.date = .now
            e.content = text
            e.tag = tags[activeTag]
            e.feature = .journal
            e.liturgicalSeason = LiturgicalCalendar.currentSeason()
            context.insert(e)
        }
        try? context.save()
        dismiss()
    }

    private var paper: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(t.surface)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(t.rule, lineWidth: 0.5))
                .overlay(
                    RuledLines(spacing: 28).stroke(t.ruleSoft, lineWidth: 1)
                        .padding(.vertical, 20).clipShape(.rect(cornerRadius: 14)))
                .lumenShadow(t)

            // red margin line
            Rectangle().fill(pal.accent.opacity(0.4))
                .frame(width: 0.5)
                .padding(.vertical, 12)
                .offset(x: 44)

            TextField("", text: $text, prompt: Text("Begin writing…").foregroundStyle(t.inkSoft),
                      axis: .vertical)
                .focused($focused)
                .font(LumenType.serif(16))
                .foregroundStyle(t.ink)
                .lineSpacing(6)
                .tint(pal.accent)
                .padding(.leading, 60)
                .padding(.trailing, 22)
                .padding(.vertical, 22)
                .frame(minHeight: 300, alignment: .topLeading)
        }
    }

    private var tagRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Tag this entry", color: t.inkSoft)
            FlowLayout(spacing: 6, lineSpacing: 6) {
                ForEach(Array(tags.enumerated()), id: \.offset) { i, tag in
                    let active = i == activeTag
                    Button { activeTag = i } label: {
                        Text(tag)
                            .font(LumenType.ui(11))
                            .foregroundStyle(active ? .white : t.inkMid)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(active ? pal.accent : t.surface, in: .capsule)
                            .overlay(Capsule().strokeBorder(active ? .clear : t.rule, lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var dateTitle: String {
        Date().formatted(.dateTime.month(.abbreviated).day()) + " · "
            + Date().formatted(.dateTime.weekday(.wide))
    }
}

#Preview {
    ComposeScreen()
        .environment(\.lumenTokens, .parchment)
        .environment(\.lumenPalette, .for(.easter))
        .modelContainer(PreviewSupport.container)
}
