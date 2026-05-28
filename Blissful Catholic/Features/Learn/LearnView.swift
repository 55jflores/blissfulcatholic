//
//  LearnView.swift
//  Blissful Catholic
//
//  Tab 3 — formation, reskinned to Lumen: a featured course, your in-progress
//  paths, and the library shelves. The Catechism companion / course readers go
//  live with the AI features (Phase 4); entries are visual for now.
//

import SwiftUI

struct LearnView: View {
    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal

    private let paths: [(title: String, meta: String, pct: Double, hue: Double, cover: String)] = [
        ("The Catechism in 90 Days", "Day 23 · CCC §301", 0.26, 30, "CCC"),
        ("Gospel of John", "Chapter 14 · Lectio", 0.48, 70, "JN"),
        ("Lives of the Saints", "Augustine · Confessions III", 0.12, 50, "VITAE"),
    ]

    private let shelves: [(name: String, count: String, symbol: String)] = [
        ("Bible", "73 books · DR + RSV", "book.closed"),
        ("Catechism", "2865 paragraphs", "cross"),
        ("Saints", "156 biographies", "heart"),
        ("Apologetics", "420 questions", "questionmark.bubble"),
        ("Church History", "20 centuries", "bookmark"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                LumenScreenHeader(eyebrow: "Learn", title: "Learn") {
                    LumenIconButton(systemImage: "magnifyingglass")
                }

                featuredCourse
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Eyebrow(text: "Continue", color: t.inkSoft)
                        Spacer()
                        Text("3 in progress")
                            .font(LumenType.ui(11))
                            .foregroundStyle(pal.accent)
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 10)

                    ForEach(Array(paths.enumerated()), id: \.offset) { _, p in
                        pathCard(p)
                            .padding(.bottom, 10)
                    }

                    Eyebrow(text: "Library", color: t.inkSoft)
                        .padding(.horizontal, 4)
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                    libraryCard
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 120)
        }
        .background(t.bg.ignoresSafeArea())
    }

    // MARK: Featured

    private var featuredCourse: some View {
        VStack(alignment: .leading, spacing: 0) {
            ArtPlate(label: "JOHN PAUL II · WEDNESDAY AUDIENCES", hue: 40, height: 170, cornerRadius: 0)

            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: "Featured Course · 12 lessons", color: pal.accent)
                Text("The Theology of the Body")
                    .font(LumenType.display(26))
                    .foregroundStyle(t.ink)
                Text("St. John Paul II's vision of the human person — read alongside the original audiences.")
                    .font(LumenType.serif(13))
                    .foregroundStyle(t.inkMid)
                    .lineSpacing(3)
                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill").font(.system(size: 10))
                        Text("Begin lesson 1").font(LumenType.ui(12, weight: .medium))
                    }
                    .foregroundStyle(t.bg)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(t.ink, in: .capsule)

                    Text("~14 min each")
                        .font(LumenType.ui(11))
                        .foregroundStyle(t.inkSoft)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(t.surface)
        .clipShape(.rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(t.rule, lineWidth: 0.5))
        .lumenShadow(t)
    }

    // MARK: Path card

    private func pathCard(_ p: (title: String, meta: String, pct: Double, hue: Double, cover: String)) -> some View {
        LumenCard(padding: 14) {
            HStack(spacing: 14) {
                ArtPlate(label: p.cover, hue: p.hue, width: 56, height: 70, vignette: false)
                VStack(alignment: .leading, spacing: 4) {
                    Text(p.title)
                        .font(LumenType.display(18))
                        .foregroundStyle(t.ink)
                        .lineLimit(2)
                    Text(p.meta)
                        .font(LumenType.ui(11))
                        .foregroundStyle(t.inkSoft)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(t.surface3)
                            Capsule().fill(pal.accent)
                                .frame(width: max(3, geo.size.width * p.pct))
                        }
                    }
                    .frame(height: 3)
                    .padding(.top, 4)
                }
            }
        }
    }

    // MARK: Library

    private var libraryCard: some View {
        LumenCard(padding: 0) {
            VStack(spacing: 0) {
                ForEach(Array(shelves.enumerated()), id: \.offset) { i, s in
                    HStack(spacing: 14) {
                        Image(systemName: s.symbol)
                            .font(.system(size: 15))
                            .foregroundStyle(pal.accent)
                            .frame(width: 30, height: 30)
                            .background(t.surface3, in: .rect(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(t.rule, lineWidth: 0.5))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.name)
                                .font(LumenType.display(17))
                                .foregroundStyle(t.ink)
                            Text(s.count)
                                .font(LumenType.ui(11))
                                .foregroundStyle(t.inkSoft)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13))
                            .foregroundStyle(t.inkSoft)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .overlay(alignment: .top) {
                        if i > 0 { Rectangle().fill(t.ruleSoft).frame(height: 0.5) }
                    }
                }
            }
        }
    }
}

#Preview {
    LearnView()
        .environment(\.lumenTokens, .parchment)
        .environment(\.lumenPalette, .for(.easter))
}
