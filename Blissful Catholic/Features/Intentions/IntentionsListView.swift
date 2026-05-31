//
//  IntentionsListView.swift
//  Blissful Catholic
//
//  Full list of prayer intentions — active section (default) plus a collapsible
//  Answered section. + FAB to add. Tap a row to edit; "I prayed" pill on each
//  active row logs a prayer for that intention (once per day per intention).
//

import SwiftUI
import SwiftData

struct IntentionsListView: View {
    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(filter: #Predicate<Intention> { $0.completedAt == nil },
           sort: \Intention.createdAt, order: .reverse)
    private var active: [Intention]

    @Query(filter: #Predicate<Intention> { $0.completedAt != nil },
           sort: \Intention.completedAt, order: .reverse)
    private var answered: [Intention]

    @State private var composeNew = false
    @State private var editing: Intention?
    @State private var showAnswered = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    LumenDeepHeader(eyebrow: "Intentions",
                                    title: "Your Intentions",
                                    onBack: { dismiss() })

                    if active.isEmpty {
                        emptyActive
                    } else {
                        VStack(spacing: 0) {
                            ForEach(active) { intention in
                                intentionRow(intention)
                            }
                        }
                        .padding(.top, 8)
                    }

                    if !answered.isEmpty {
                        answeredSection
                    }
                }
                .padding(.bottom, 140)
            }
            .background(t.bg.ignoresSafeArea())

            addButton
                .padding(.trailing, 22)
                .padding(.bottom, 104)  // clears the floating Lumen tab bar
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $composeNew) {
            ComposeIntentionView()
        }
        .sheet(item: $editing) { intention in
            ComposeIntentionView(intention: intention)
        }
    }

    // MARK: Active rows

    private func intentionRow(_ intention: Intention) -> some View {
        HStack(spacing: 14) {
            // Tap target: candle + text → opens edit sheet.
            HStack(spacing: 14) {
                Candle(size: 24, lit: true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(intention.text)
                        .font(LumenType.display(17))
                        .foregroundStyle(t.ink)
                        .multilineTextAlignment(.leading)
                    metaLine(intention)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { editing = intention }

            prayedButton(for: intention)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(t.ruleSoft).frame(height: 0.5)
        }
    }

    private func metaLine(_ intention: Intention) -> some View {
        HStack(spacing: 6) {
            Text("Day \(intention.dayCount)")
            Text("·")
            Text("\(intention.prayerCount) \(intention.prayerCount == 1 ? "prayer" : "prayers")")
            if intention.prayedToday {
                Text("· prayed today")
                    .foregroundStyle(pal.accent)
            }
        }
        .font(LumenType.ui(11))
        .foregroundStyle(t.inkSoft)
    }

    private func prayedButton(for intention: Intention) -> some View {
        Button { logPrayed(intention) } label: {
            Text(intention.prayedToday ? "Prayed" : "I prayed")
                .font(LumenType.ui(11, weight: .medium))
                .foregroundStyle(intention.prayedToday ? .white : pal.accent)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(intention.prayedToday ? pal.accent : .clear, in: .capsule)
                .overlay(Capsule()
                    .strokeBorder(intention.prayedToday ? .clear : pal.accent.opacity(0.5),
                                  lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: intention.prayedToday) { _, now in now }
    }

    private func logPrayed(_ intention: Intention) {
        guard !intention.prayedToday else { return }
        intention.prayerCount += 1
        intention.lastPrayedAt = .now

        // Also create a PrayerSession so the day shows up as "active" in the
        // streak garden — same behavior as the Daily card's "I prayed" pill.
        let session = PrayerSession()
        session.date = .now
        session.feature = .intention
        session.completed = true
        session.notes = intention.text
        context.insert(session)

        try? context.save()
    }

    // MARK: Empty state

    private var emptyActive: some View {
        VStack(spacing: 10) {
            Image(systemName: "flame")
                .font(.system(size: 32))
                .foregroundStyle(t.inkSoft)
            Text("No active intentions")
                .font(LumenType.display(20))
                .foregroundStyle(t.ink)
            Text("Tap the + button to set your first intention.")
                .font(LumenType.serif(13))
                .foregroundStyle(t.inkMid)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: Answered section

    private var answeredSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { withAnimation(.easeInOut(duration: 0.2)) { showAnswered.toggle() } } label: {
                HStack {
                    Text("Answered (\(answered.count))")
                        .font(LumenType.display(16))
                        .foregroundStyle(t.inkMid)
                    Spacer()
                    Image(systemName: showAnswered ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13))
                        .foregroundStyle(t.inkSoft)
                }
                .padding(.horizontal, 20).padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            if showAnswered {
                VStack(spacing: 0) {
                    ForEach(answered) { intention in
                        answeredRow(intention)
                    }
                }
            }
        }
        .padding(.top, 28)
        .overlay(alignment: .top) {
            Rectangle().fill(t.ruleSoft).frame(height: 0.5).padding(.top, 28)
        }
    }

    private func answeredRow(_ intention: Intention) -> some View {
        HStack(spacing: 14) {
            Candle(size: 24, lit: false)
            VStack(alignment: .leading, spacing: 4) {
                Text(intention.text)
                    .font(LumenType.display(16))
                    .foregroundStyle(t.inkMid)
                    .multilineTextAlignment(.leading)
                if let completedAt = intention.completedAt {
                    Text("Answered \(completedAt.formatted(.relative(presentation: .named)))")
                        .font(LumenType.ui(11))
                        .foregroundStyle(t.inkSoft)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundStyle(t.inkSoft)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .contentShape(.rect)
        .onTapGesture { editing = intention }
        .overlay(alignment: .bottom) {
            Rectangle().fill(t.ruleSoft).frame(height: 0.5)
        }
    }

    // MARK: FAB

    private var addButton: some View {
        Button { composeNew = true } label: {
            Image(systemName: "plus")
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
    NavigationStack {
        IntentionsListView()
    }
    .environment(\.lumenTokens, .parchment)
    .environment(\.lumenPalette, .for(.ordinaryTime))
    .modelContainer(PreviewSupport.container)
}
