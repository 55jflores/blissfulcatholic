//
//  DailyView.swift
//  Blissful Catholic
//
//  Tab 1 — the home, in Lumen. Verse of the day, today's Mass readings, the
//  saint of the day, a reflection, and a burning-candle intention. The readings,
//  saint, and reflection now push their detail screens.
//

import SwiftUI
import SwiftData

enum DailyRoute: Hashable {
    case reading(ReadingItem)
    case saint
    case reflection
}

struct DailyView: View {
    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal
    @Environment(\.modelContext) private var context

    @State private var prayed = false
    @State private var showReflection = false
    private let now = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    LumenScreenHeader(eyebrow: "\(pal.name) · \(weekday)", title: monthDay) {
                        LumenIconButton(systemImage: "bell")
                    }

                    verse
                    Ornament(color: t.inkSoft)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 22)

                    VStack(spacing: 16) {
                        reflectWithAI
                        readingsCard
                        NavigationLink(value: DailyRoute.saint) { saintCard }
                            .buttonStyle(.plain)
                        NavigationLink(value: DailyRoute.reflection) { reflectionCard }
                            .buttonStyle(.plain)
                        intentionSection
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 120)
            }
            .background(t.bg.ignoresSafeArea())
            .navigationDestination(for: DailyRoute.self) { route in
                switch route {
                case .reading(let r): ReadingScreen(reading: r)
                case .saint:          SaintScreen()
                case .reflection:     ReflectionScreen()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showReflection) {
            AIReflectionView(
                feature: "daily",
                prompt: "Give me a short, personal reflection to pray with today."
            )
        }
    }

    // MARK: Reflect with AI

    private var reflectWithAI: some View {
        Button { showReflection = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles").font(.system(size: 16))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reflect with your companion")
                        .font(LumenType.ui(14, weight: .medium))
                    Text("A reflection shaped for you, today")
                        .font(LumenType.serif(12).italic())
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.right").font(.system(size: 13))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18).padding(.vertical, 16)
            .background(
                LinearGradient(colors: [pal.accent, pal.accentSoft],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: .rect(cornerRadius: 16)
            )
            .lumenShadow(t)
        }
        .buttonStyle(.plain)
    }

    // MARK: Verse hero

    private var verse: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("“The Lord has truly been raised, and has appeared to Simon.”")
                .font(LumenType.display(26, weight: .medium).italic())
                .foregroundStyle(t.ink)
                .lineSpacing(4)
            Eyebrow(text: "Luke 24:34", color: t.inkSoft)
        }
        .padding(.horizontal, 24)
        .padding(.top, 6)
        .padding(.bottom, 22)
    }

    // MARK: Mass readings

    private let readings: [ReadingItem] = [
        ReadingItem(
            label: "First Reading", citation: "Acts 18:9–18",
            heading: "A reading from the Acts of the Apostles.",
            body: """
            In those days, the Lord said to Paul in a vision during the night, "Do not be afraid. Go on speaking, and do not be silent, for I am with you. No one will attack and harm you, for I have many people in this city." He settled there for a year and a half and taught the word of God among them.

            When Gallio was proconsul of Achaia, the Jews rose up together against Paul and brought him to the tribunal. But Gallio said, "Since it is a question of arguments over doctrine and your own law, see to it yourselves. I do not wish to be a judge of such matters." And he drove them away from the tribunal.
            """,
            response: "The Word of the Lord. Thanks be to God."),
        ReadingItem(
            label: "Responsorial", citation: "Psalm 47:2–7",
            heading: "God is king of all the earth.",
            body: """
            All you peoples, clap your hands; shout to God with cries of gladness. For the LORD, the Most High, the awesome, is the great king over all the earth.

            God reigns over the nations, God sits upon his holy throne. Sing praise to God, sing praise; sing praise to our king, sing praise.
            """,
            response: "Sing praise to God, sing praise."),
        ReadingItem(
            label: "Gospel", citation: "John 16:20–23",
            heading: "A reading from the holy Gospel according to John.",
            body: """
            Jesus said to his disciples: "Amen, amen, I say to you, you will weep and mourn, while the world rejoices; you will grieve, but your grief will become joy.

            So you also are now in anguish. But I will see you again, and your hearts will rejoice, and no one will take your joy away from you."
            """,
            response: "The Gospel of the Lord. Praise to you, Lord Jesus Christ."),
    ]

    private var readingsCard: some View {
        LumenCard(padding: 0) {
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(text: "Mass · \(weekday) of the 6th Week", color: pal.accent)
                        Text("Today's Readings")
                            .font(LumenType.display(22))
                            .foregroundStyle(t.ink)
                    }
                    Spacer()
                    Text("~12 min").font(LumenType.ui(11)).foregroundStyle(t.inkSoft)
                }
                .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 12)

                ForEach(Array(readings.enumerated()), id: \.offset) { i, r in
                    NavigationLink(value: DailyRoute.reading(r)) {
                        readingRow(index: i, reading: r)
                    }
                    .buttonStyle(.plain)
                }

                HStack {
                    Text("Read with audio").font(LumenType.ui(12)).foregroundStyle(t.inkMid)
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill").font(.system(size: 10))
                        Text("Begin").font(LumenType.ui(12, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(pal.accent, in: .capsule)
                }
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(t.surface2)
                .overlay(Rectangle().fill(t.ruleSoft).frame(height: 0.5), alignment: .top)
            }
        }
    }

    private func readingRow(index i: Int, reading r: ReadingItem) -> some View {
        HStack(spacing: 14) {
            Text(["i", "ii", "iii"][i])
                .font(LumenType.display(16, weight: .semibold).italic())
                .foregroundStyle(pal.accent)
                .frame(width: 30, height: 30)
                .background(t.surface3, in: .circle)
                .overlay(Circle().strokeBorder(t.rule, lineWidth: 0.5))
            VStack(alignment: .leading, spacing: 3) {
                Eyebrow(text: "\(r.label) · \(r.citation)", color: t.inkSoft)
                Text(r.body.replacingOccurrences(of: "\n", with: " "))
                    .font(LumenType.serif(14))
                    .foregroundStyle(t.ink)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(t.inkSoft)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .overlay(Rectangle().fill(t.ruleSoft).frame(height: 0.5), alignment: .top)
    }

    // MARK: Saint of the day

    private var saintCard: some View {
        LumenCard(padding: 0) {
            HStack(spacing: 0) {
                ArtPlate(label: "ST. RITA · 1381", hue: 20, width: 108, height: 130, cornerRadius: 0)
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Eyebrow(text: "Memorial", color: pal.accent)
                        Text("St. Rita of Cascia").font(LumenType.display(22)).foregroundStyle(t.ink)
                        Text("Patroness of impossible causes")
                            .font(LumenType.serif(12).italic()).foregroundStyle(t.inkMid)
                    }
                    Spacer(minLength: 0)
                    Text("Wife, mother, widow, and Augustinian — known for the wound she bore on her forehead.")
                        .font(LumenType.serif(12)).foregroundStyle(t.inkMid).lineSpacing(2)
                }
                .padding(.horizontal, 18).padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: Reflection

    private var reflectionCard: some View {
        LumenCard {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "Reflection · 3 min read", color: pal.accent)
                Text("On the kind of joy that does not depend on circumstance.")
                    .font(LumenType.display(19)).foregroundStyle(t.ink).lineSpacing(2)
                Text("“Your grief will become joy” — not be replaced, not be undone. The Lord names a transformation only sorrow can prepare us for…")
                    .font(LumenType.serif(13)).foregroundStyle(t.inkMid).lineSpacing(3)
                HStack(spacing: 8) {
                    Text("F")
                        .font(LumenType.display(12).italic()).foregroundStyle(t.goldDeep)
                        .frame(width: 22, height: 22).background(t.surface3, in: .circle)
                    Text("Fr. Henri Nouwen, OP").font(LumenType.ui(11)).foregroundStyle(t.inkSoft)
                }
                .padding(.top, 6)
            }
        }
    }

    // MARK: Intention

    private var intentionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Today's intention", color: t.inkSoft).padding(.horizontal, 4)
            LumenCard(padding: 16) {
                HStack(spacing: 14) {
                    Candle(size: 22, lit: prayed)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("For my mother's health.").font(LumenType.display(17)).foregroundStyle(t.ink)
                        Text("Day 4 · burning").font(LumenType.ui(11)).foregroundStyle(t.inkSoft)
                    }
                    Spacer(minLength: 0)
                    Button { logPrayed() } label: {
                        Text(prayed ? "Prayed" : "I prayed")
                            .font(LumenType.ui(11, weight: .medium))
                            .foregroundStyle(prayed ? .white : pal.accent)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(prayed ? pal.accent : .clear, in: .capsule)
                            .overlay(Capsule().strokeBorder(prayed ? .clear : t.rule, lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.success, trigger: prayed) { _, now in now }
                }
            }
        }
    }

    private func logPrayed() {
        if !prayed {
            let session = PrayerSession()
            session.date = .now
            session.feature = .examen
            session.completed = true
            session.notes = "Intention"
            context.insert(session)
            try? context.save()
        }
        prayed.toggle()
    }

    private var weekday: String { now.formatted(.dateTime.weekday(.wide)) }
    private var monthDay: String { now.formatted(.dateTime.month(.abbreviated).day()) }
}

#Preview {
    DailyView()
        .environment(\.lumenTokens, .parchment)
        .environment(\.lumenPalette, .for(.easter))
        .modelContainer(PreviewSupport.container)
}
