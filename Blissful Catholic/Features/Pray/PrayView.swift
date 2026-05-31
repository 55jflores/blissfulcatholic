//
//  PrayView.swift
//  Blissful Catholic
//
//  Tab 2 — the prayer hub, reskinned to Lumen: a resume-prayer hero, a 2×3 grid
//  of practices, burning-candle intentions, and the prayer library. The Rosary
//  deep screen (the marquee interaction) is built in the next slice, so the
//  rosary entries are visually present but not yet navigating.
//

import SwiftUI

enum PrayRoute: Hashable { case rosary(resume: Bool) }

struct PrayView: View {
    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal
    @State private var progress: RosaryProgress?
    @State private var showConfession = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    LumenScreenHeader(eyebrow: "Pray", title: "Pray")

                    NavigationLink(value: PrayRoute.rosary(resume: progress != nil)) { heroCard }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)

                    AICTAButton(title: "Prepare for Confession",
                                subtitle: "A gentle examination of conscience") {
                        showConfession = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)

                    // TestFlight hiding pass: practice grid (5 of 6 tiles unwired),
                    // intentions card (hardcoded counts and candle states), and the
                    // library row (no destination) hidden until each gets a real backing.
            }
                .padding(.bottom, 120)
            }
            .background(t.bg.ignoresSafeArea())
            .onAppear { progress = RosaryProgressStore.load() }
            .navigationDestination(for: PrayRoute.self) { route in
                switch route {
                case .rosary(let resume): RosaryView(resume: resume)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showConfession) {
            AIReflectionView(
                feature: "confession_prep",
                prompt: "Help me examine my conscience and prepare for the Sacrament of Reconciliation.",
                title: "Examination of Conscience",
                reason: "Sign in to prepare for Confession."
            )
        }
    }

    // MARK: Resume / start hero

    @ViewBuilder
    private var heroCard: some View {
        if let progress {
            let info = heroInfo(progress)
            heroBody(eyebrow: "Resume · paused \(relative(progress.savedAt))",
                     title: info.title, subtitle: info.subtitle, fraction: info.fraction)
        } else {
            heroBody(eyebrow: "Today's Rosary",
                     title: MysterySet.recommended().displayName,
                     subtitle: "Begin a new Rosary",
                     fraction: 0)
        }
    }

    private func heroBody(eyebrow: String, title: String, subtitle: String, fraction: Double) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "cross.fill")
                .font(.system(size: 90))
                .foregroundStyle(.white.opacity(0.08))
                .offset(x: 12, y: -8)

            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: eyebrow, color: .white.opacity(0.7))
                Text(title)
                    .font(LumenType.display(26))
                    .foregroundStyle(.white)
                    .padding(.top, 6)
                Text(subtitle)
                    .font(LumenType.serif(13).italic())
                    .foregroundStyle(.white.opacity(0.88))
                    .padding(.top, 4)

                HStack(spacing: 14) {
                    HStack(spacing: 3) {
                        ForEach(0..<36, id: \.self) { i in
                            Capsule()
                                .fill(.white.opacity(Double(i) < fraction * 36 ? 0.95 : 0.25))
                                .frame(height: 4)
                        }
                    }
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(pal.accent)
                        .frame(width: 36, height: 36)
                        .background(.white, in: .circle)
                }
                .padding(.top, 18)
            }
            .padding(20)
        }
        .background(
            LinearGradient(colors: [pal.accent, pal.accentSoft],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: .rect(cornerRadius: 18))
        .shadow(color: Color(hex: 0x52351d, alpha: 0.18), radius: 12, y: 8)
    }

    /// Derive the resume hero's title / current-step line / progress from saved state.
    private func heroInfo(_ p: RosaryProgress) -> (title: String, subtitle: String, fraction: Double) {
        let model = RosaryViewModel(mystery: p.mystery)
        model.setIndex(p.index)
        return (p.mystery.displayName, model.current.context, model.progress)
    }

    private func relative(_ date: Date) -> String {
        date.formatted(.relative(presentation: .named))
    }

    // MARK: Practice grid

    private let practices: [(title: String, duration: String, symbol: String)] = [
        ("Rosary", "20 MIN · 4 mysteries", "circle.grid.cross"),
        ("Liturgy of the Hours", "LAUDS · VESPERS · COMPLINE", "cross"),
        ("The Examen", "10 MIN · evening", "heart"),
        ("Lectio Divina", "15 MIN · scripture", "book.closed"),
        ("Novenas", "9 DAY · structured", "flame"),
        ("Adoration", "TIMER · silent", "sun.max"),
    ]

    private var practiceGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(Array(practices.enumerated()), id: \.offset) { _, p in
                if p.title == "Rosary" {
                    NavigationLink(value: PrayRoute.rosary(resume: false)) {
                        PracticeTile(title: p.title, duration: p.duration, symbol: p.symbol)
                    }
                    .buttonStyle(.plain)
                } else {
                    PracticeTile(title: p.title, duration: p.duration, symbol: p.symbol)
                }
            }
        }
    }

    // MARK: Intentions

    private var intentionsCard: some View {
        LumenCard(padding: 0) {
            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Candles burning")
                            .font(LumenType.display(19))
                            .foregroundStyle(t.ink)
                        Text("Six intentions held in prayer this week.")
                            .font(LumenType.serif(12).italic())
                            .foregroundStyle(t.inkMid)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(t.inkSoft)
                        .padding(.top, 6)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 8)

                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(Array([true, true, true, false, true, true].enumerated()), id: \.offset) { _, lit in
                        Candle(size: 20, lit: lit)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .padding(.bottom, 14)
                .background(
                    LinearGradient(colors: [t.surface3, .clear],
                                   startPoint: .bottom, endPoint: .top))
            }
        }
    }

    // MARK: Library

    private var libraryRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Prayer Library")
                    .font(LumenType.display(17))
                    .foregroundStyle(t.ink)
                Text("Traditional prayers · Litanies · Devotions")
                    .font(LumenType.ui(11))
                    .foregroundStyle(t.inkSoft)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundStyle(t.inkSoft)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(t.surface2, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(t.rule, lineWidth: 0.5))
    }
}

// MARK: - Practice tile

private struct PracticeTile: View {
    let title: String
    let duration: String
    let symbol: String

    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundStyle(pal.accent)
                .frame(width: 36, height: 36)
                .background(t.surface3, in: .circle)
                .overlay(Circle().strokeBorder(t.rule, lineWidth: 0.5))

            Spacer(minLength: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(LumenType.display(19))
                    .foregroundStyle(t.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(duration)
                    .font(LumenType.ui(10))
                    .tracking(0.4)
                    .foregroundStyle(t.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .padding(16)
        .background(t.surface, in: .rect(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(t.rule, lineWidth: 0.5))
        .lumenShadow(t)
    }
}

#Preview {
    PrayView()
        .environment(\.lumenTokens, .parchment)
        .environment(\.lumenPalette, .for(.easter))
}
