//
//  DailyDeepScreens.swift
//  Blissful Catholic
//
//  The deep screens reached from the Daily tab: a reading detail (drop cap),
//  the saint detail, and the reflection reader. Content is hardcoded sample for
//  Phase 1 — scripture comes from API.Bible and reflections from Claude in
//  Phase 4.
//

import SwiftUI

// MARK: - Reading

/// A Mass reading, passed from Daily into the detail screen.
struct ReadingItem: Hashable {
    let label: String      // "First Reading"
    let citation: String   // "Acts 18:9–18"
    let heading: String    // "A reading from the Acts of the Apostles."
    let body: String       // full passage; paragraphs separated by "\n\n"
    let response: String   // "Thanks be to God." / "Praise to you, Lord Jesus Christ."
}

struct ReadingScreen: View {
    let reading: ReadingItem
    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            LumenDeepHeader(eyebrow: reading.label, title: reading.citation, onBack: { dismiss() }) {
                LumenIconButton(systemImage: "bookmark")
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow(text: reading.label, color: pal.accent).padding(.bottom, 10)
                    Text(reading.heading)
                        .font(LumenType.display(30))
                        .foregroundStyle(t.ink)
                        .tracking(-0.4)
                    Ornament(color: pal.accent).frame(maxWidth: 220).padding(.vertical, 22)

                    DropCapText(reading.body)

                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow(text: "The Word of the Lord", color: t.inkSoft)
                        Text(reading.response)
                            .font(LumenType.display(18).italic())
                            .foregroundStyle(t.ink)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(t.surface2, in: .rect(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(t.rule, lineWidth: 0.5))
                    .padding(.top, 24)
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 140)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// Body text with a large serif drop cap on the first letter.
private struct DropCapText: View {
    let text: String
    init(_ text: String) { self.text = text }

    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal

    var body: some View {
        let paragraphs = text.components(separatedBy: "\n\n")
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { i, para in
                if i == 0, let first = para.first {
                    (Text(String(first))
                        .font(LumenType.display(52))
                        .foregroundStyle(pal.accent)
                     + Text(String(para.dropFirst()))
                        .font(LumenType.serif(17))
                        .foregroundStyle(t.ink))
                    .lineSpacing(6)
                } else {
                    Text(para)
                        .font(LumenType.serif(17))
                        .foregroundStyle(t.ink)
                        .lineSpacing(6)
                }
            }
        }
    }
}

// MARK: - Saint

struct SaintScreen: View {
    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal
    @Environment(\.dismiss) private var dismiss

    private let patronages = ["Impossible causes", "Abused wives", "Widows", "Wounded"]
    private let bio = [
        "Born in Roccaporena, Umbria, Rita longed for the cloister from a young age but was given in marriage at twelve to a hot-tempered nobleman. For eighteen years she endured his cruelty in patience and prayer, eventually winning his conversion shortly before he was murdered in a vendetta.",
        "Her two sons swore to avenge their father. Rita prayed they might die rather than commit the sin of revenge — and within the year both succumbed to illness, reconciled to God.",
        "Widowed and childless, she sought entry into the Augustinian monastery at Cascia. Refused three times, she was finally admitted after, by tradition, her patron saints transported her there in the night.",
    ]

    var body: some View {
        VStack(spacing: 0) {
            LumenDeepHeader(eyebrow: "Memorial · May 22", title: "St. Rita of Cascia", onBack: { dismiss() }) {
                LumenIconButton(systemImage: "bookmark")
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ArtPlate(label: "ST. RITA · MARGHERITA LOTTI · 1381–1457", hue: 15, height: 260, cornerRadius: 0)

                    VStack(alignment: .leading, spacing: 0) {
                        Eyebrow(text: "Patroness of Impossible Causes", color: pal.accent)
                        Text("St. Rita of Cascia")
                            .font(LumenType.display(36))
                            .foregroundStyle(t.ink)
                            .tracking(-0.5)
                            .padding(.top, 8)
                        Text("Wife, mother, widow, Augustinian nun.")
                            .font(LumenType.serif(14).italic())
                            .foregroundStyle(t.inkMid)
                            .padding(.top, 6)

                        Ornament(color: pal.accent).padding(.vertical, 22)

                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(Array(bio.enumerated()), id: \.offset) { _, p in
                                Text(p).font(LumenType.serif(15)).foregroundStyle(t.ink).lineSpacing(6)
                            }
                        }

                        FlowLayout(spacing: 6, lineSpacing: 6) {
                            ForEach(patronages, id: \.self) { tag in
                                Text(tag)
                                    .font(LumenType.ui(11))
                                    .foregroundStyle(t.inkMid)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(t.surface, in: .capsule)
                                    .overlay(Capsule().strokeBorder(t.rule, lineWidth: 0.5))
                            }
                        }
                        .padding(.top, 22)

                        VStack(alignment: .leading, spacing: 6) {
                            Eyebrow(text: "Prayer to St. Rita", color: t.inkSoft)
                            Text("“O holy patroness of those in need, pray for us in this hour — that no cause may seem too lost to bring before the Father.”")
                                .font(LumenType.display(17).italic())
                                .foregroundStyle(t.ink)
                                .lineSpacing(3)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(t.surface2, in: .rect(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(t.rule, lineWidth: 0.5))
                        .padding(.top, 22)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 140)
                }
            }
        }
        .background(t.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Reflection

struct ReflectionScreen: View {
    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal
    @Environment(\.dismiss) private var dismiss

    private let paragraphs = [
        "“Your grief will become joy.” The Lord does not say it will be replaced. He does not say it will be undone. He names a transformation — a turning — that only sorrow could have prepared.",
        "This is hard to receive. We are tempted to imagine joy as a kind of forgetting, or as the absence of suffering. But the Risen Lord still bears his wounds. The glorified body of the Son of God carries the marks of nails.",
        "What if the joy he promises is exactly the kind that remembers — that holds the whole of our story, and finds, at the bottom, that we were not alone?",
    ]

    var body: some View {
        VStack(spacing: 0) {
            LumenDeepHeader(eyebrow: "Reflection · 3 min", title: "Friday of Easter VI") { dismiss() }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow(text: "On joy that is given", color: pal.accent)
                    Text("The kind of joy that does not depend on circumstance.")
                        .font(LumenType.display(30))
                        .foregroundStyle(t.ink)
                        .tracking(-0.4)
                        .padding(.top, 8)

                    Ornament(color: pal.accent).padding(.vertical, 24)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, p in
                            Text(p).font(LumenType.serif(16)).foregroundStyle(t.ink).lineSpacing(6)
                        }
                    }

                    HStack(spacing: 12) {
                        Text("N")
                            .font(LumenType.display(16).italic())
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(LinearGradient(colors: [pal.accent, pal.accentSoft],
                                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                                        in: .circle)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fr. Henri Nouwen, OP").font(LumenType.display(15)).foregroundStyle(t.ink)
                            Text("Adapted from The Inner Voice of Love")
                                .font(LumenType.ui(11)).foregroundStyle(t.inkSoft)
                        }
                        Spacer()
                        Image(systemName: "heart").foregroundStyle(pal.accent)
                    }
                    .padding(14)
                    .background(t.surface2, in: .rect(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(t.rule, lineWidth: 0.5))
                    .padding(.top, 24)
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 140)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}
