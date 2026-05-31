//
//  JournalView.swift
//  Blissful Catholic
//
//  Tab 4 — the spiritual journal, now backed by SwiftData. Real entries via
//  @Query; the prompt / FAB compose a new entry; tapping an entry opens it.
//

import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @State private var composeNew = false
    @State private var editingEntry: JournalEntry?

    private let chips = ["Gratitude", "Free entry", "Confession prep", "After Mass", "Intentions"]
    private let activeChip = 1

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    LumenScreenHeader(eyebrow: "Journal", title: "Journal")

                    Button { composeNew = true } label: { promptCard }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)

                    // TestFlight hiding pass: tag-filter chips hidden — they were visual
                    // only (activeChip was a fixed index, no filtering wired).

                    Eyebrow(text: "Recent entries · \(entries.count) total", color: t.inkSoft)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 14)

                    if entries.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 0) {
                            ForEach(entries) { e in
                                Button { editingEntry = e } label: { entryRow(e) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 120)
            }
            .background(t.bg.ignoresSafeArea())

            writeButton
                .padding(.trailing, 22)
                .padding(.bottom, 104)
        }
        .fullScreenCover(isPresented: $composeNew) { ComposeScreen() }
        .fullScreenCover(item: $editingEntry) { entry in ComposeScreen(entry: entry) }
    }

    // MARK: Prompt

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "Examen Prompt", color: pal.accent).padding(.bottom, 8)
            Text("Where did you sense God's presence today, even briefly?")
                .font(LumenType.display(24).italic())
                .foregroundStyle(t.ink)
                .lineSpacing(3)
            HStack {
                Text("~5 min · guided").font(LumenType.ui(11)).foregroundStyle(t.inkSoft)
                Spacer()
                Text("Begin writing")
                    .font(LumenType.ui(12, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 9)
                    .background(pal.accent, in: .capsule)
            }
            .padding(.top, 18)
        }
        .padding(20)
        .background(t.surface2)
        .background(RuledLines(spacing: 28).stroke(t.ruleSoft, lineWidth: 1).padding(.top, 12))
        .clipShape(.rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(t.rule, lineWidth: 0.5))
        .lumenShadow(t)
    }

    private func chip(_ text: String, active: Bool) -> some View {
        Text(text)
            .font(LumenType.ui(11))
            .foregroundStyle(active ? t.bg : t.inkMid)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(active ? t.ink : t.surface, in: .capsule)
            .overlay(Capsule().strokeBorder(active ? .clear : t.rule, lineWidth: 0.5))
    }

    // MARK: Entry row

    private func entryRow(_ e: JournalEntry) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 2) {
                Text(e.date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                    .font(LumenType.ui(10)).tracking(1.0).foregroundStyle(t.inkSoft)
                Text(e.date.formatted(.dateTime.day()))
                    .font(LumenType.display(22)).foregroundStyle(t.ink)
                Text(e.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(LumenType.mono(8)).tracking(0.5).foregroundStyle(t.inkSoft)
            }
            .frame(width: 44)
            .padding(.top, 2)

            Rectangle().fill(pal.accent.opacity(0.4)).frame(width: 1)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(e.derivedTitle).font(LumenType.display(18)).foregroundStyle(t.ink)
                    Spacer(minLength: 8)
                    if !e.tag.isEmpty { Eyebrow(text: e.tag, color: pal.accent) }
                }
                if !e.derivedPreview.isEmpty {
                    Text(e.derivedPreview)
                        .font(LumenType.serif(13)).foregroundStyle(t.inkMid)
                        .lineSpacing(2).lineLimit(2)
                }
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 14).padding(.horizontal, 4)
        .overlay(alignment: .bottom) { Rectangle().fill(t.ruleSoft).frame(height: 0.5) }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "pencil.line").font(.system(size: 32)).foregroundStyle(t.inkSoft)
            Text("Your journal is empty")
                .font(LumenType.display(20)).foregroundStyle(t.ink)
            Text("Tap the pen to write your first entry.")
                .font(LumenType.serif(13)).foregroundStyle(t.inkMid)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var writeButton: some View {
        Button { composeNew = true } label: {
            Image(systemName: "pencil")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(t.bg)
                .frame(width: 56, height: 56)
                .background(t.ink, in: .circle)
                .shadow(color: .black.opacity(0.18), radius: 12, y: 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    JournalView()
        .environment(\.lumenTokens, .parchment)
        .environment(\.lumenPalette, .for(.easter))
        .modelContainer(PreviewSupport.container)
}
