//
//  RosaryView.swift
//  Blissful Catholic
//
//  The marquee interaction, in Lumen — a focused, one-decade-at-a-time walk.
//  You see only the beads of the current movement (the opening prayers, a single
//  decade, or the closing) plus five pips showing which decade you're in. A
//  "View full rosary" reveal shows the whole chain for those who want the map.
//  Haptics: light per bead, medium when a decade closes, success at the end.
//

import SwiftUI
import SwiftData

struct RosaryView: View {
    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    /// When true, restore the last paused session instead of starting fresh.
    var resume: Bool = false

    @State private var vm: RosaryViewModel
    @State private var showFull = false
    @State private var startedAt = Date()

    init(resume: Bool = false) {
        self.resume = resume
        var model = RosaryViewModel()
        if resume, let progress = RosaryProgressStore.load() {
            model.select(progress.mystery)
            model.setIndex(progress.index)
        }
        _vm = State(initialValue: model)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            t.bg.ignoresSafeArea()
            RadialGradient(colors: [pal.accent.opacity(0.16), .clear],
                           center: .top, startRadius: 0, endRadius: 360)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                LumenDeepHeader(eyebrow: vm.decadeLabel, title: "The Holy Rosary") { dismiss() }

                ScrollView {
                    VStack(spacing: 0) {
                        mysterySelector.padding(.top, 14)
                        decadePips.padding(.top, 22)
                        focusedBeads.padding(.top, 18)
                        viewFullButton.padding(.top, 14)
                        prayerBlock.padding(.top, 20)
                    }
                    .padding(.bottom, 200)
                }
            }

            controls
                .padding(.horizontal, 16)
                .padding(.bottom, 96)
        }
        .sensoryFeedback(trigger: vm.index) { _, newIndex in
            haptic(for: vm.steps[newIndex], finished: newIndex == vm.count - 1)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showFull) {
            FullRosarySheet(vm: vm)
        }
        .onDisappear {
            // Save a resumable pointer if the user left mid-rosary.
            if !vm.isFinished, vm.index > 0 {
                RosaryProgressStore.save(mystery: vm.mystery, index: vm.index)
            }
        }
    }

    // MARK: Mystery selector

    private var mysterySelector: some View {
        HStack(spacing: 6) {
            ForEach(MysterySet.allCases) { set in
                let active = vm.mystery == set
                Button { vm.select(set) } label: {
                    Text(set.rawValue.capitalized)
                        .font(LumenType.ui(10, weight: .medium))
                        .tracking(0.6).textCase(.uppercase)
                        .foregroundStyle(active ? .white : t.inkMid)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(active ? pal.accent : .clear, in: .capsule)
                        .overlay(Capsule().strokeBorder(active ? .clear : t.rule, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Decade pips

    private var decadePips: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { d in
                let phase = vm.current.phase
                let isCurrent = phase == d
                let isDone = (phase > d && phase <= 6) || phase == 6
                Capsule()
                    .fill(isCurrent ? pal.accent : (isDone ? pal.accentSoft : t.surface3))
                    .frame(width: isCurrent ? 18 : 7, height: 7)
                    .animation(.easeInOut(duration: 0.25), value: vm.index)
            }
        }
    }

    // MARK: Focused beads (only the current movement)

    private var focusedBeads: some View {
        HStack(spacing: 7) {
            ForEach(vm.phaseSteps, id: \.offset) { item in
                focusBead(item.offset, step: item.step)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: vm.index)
    }

    private func focusBead(_ i: Int, step: RosaryStep) -> some View {
        let isCurrent = i == vm.index
        let isPast = i < vm.index
        let size: CGFloat = step.isLargeBead ? 15 : 10
        let fill: Color = isCurrent ? pal.accent : (isPast ? pal.accentSoft : t.surface3)

        return Button { vm.setIndex(i) } label: {
            Circle()
                .fill(fill)
                .frame(width: size, height: size)
                .overlay(Circle().strokeBorder(isCurrent ? pal.accent : t.rule,
                                               lineWidth: isCurrent ? 1.5 : 0.5))
                .shadow(color: isCurrent ? pal.accent.opacity(0.5) : .clear, radius: 6)
                .scaleEffect(isCurrent ? 1.35 : 1)
                .frame(width: 22, height: 24)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var viewFullButton: some View {
        Button { showFull = true } label: {
            Label("View full rosary", systemImage: "circle.grid.cross")
                .font(LumenType.ui(11))
                .foregroundStyle(t.inkSoft)
        }
        .buttonStyle(.plain)
    }

    // MARK: Prayer

    private var prayerBlock: some View {
        VStack(spacing: 0) {
            Eyebrow(text: vm.current.context, color: pal.accent)
                .multilineTextAlignment(.center)
                .padding(.bottom, 14)

            Text(vm.current.prayer.name)
                .font(LumenType.display(24))
                .foregroundStyle(t.ink)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)

            if (1...5).contains(vm.current.phase) {
                Button {
                    // Phase 4: AI reflection on this mystery, tailored to the user.
                } label: {
                    Label("Reflect on this mystery", systemImage: "sparkles")
                        .font(LumenType.ui(11))
                        .foregroundStyle(pal.accent)
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
            }

            Ornament(color: pal.accent)
                .frame(maxWidth: 200)
                .padding(.vertical, 18)

            Text(vm.current.prayer.text)
                .font(LumenType.serif(16).italic())
                .foregroundStyle(t.inkMid)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(minHeight: 120, alignment: .top)
        }
        .padding(.horizontal, 28)
        .animation(.easeInOut(duration: 0.25), value: vm.index)
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 12) {
            circleButton(systemImage: "chevron.left") { vm.back() }

            Button {
                if vm.isFinished { logCompletion(); dismiss() } else { vm.advance() }
            } label: {
                Text(vm.isFinished ? "Finish" : "Amen — Next bead")
                    .font(LumenType.ui(13, weight: .medium))
                    .tracking(0.6).textCase(.uppercase)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(pal.accent, in: .capsule)
                    .shadow(color: pal.accent.opacity(0.4), radius: 12, y: 6)
            }
            .buttonStyle(.plain)

            circleButton(systemImage: "pause.fill") { dismiss() }
        }
    }

    // MARK: Logging — record a completed rosary (feeds the prayer streak).
    private func logCompletion() {
        let log = RosaryLog()
        log.date = .now
        log.mysteries = vm.mystery
        log.completed = true
        context.insert(log)

        let session = PrayerSession()
        session.date = .now
        session.feature = .rosary
        session.completed = true
        session.durationSeconds = Int(Date().timeIntervalSince(startedAt))
        context.insert(session)

        try? context.save()
        RosaryProgressStore.clear()   // finished — nothing to resume
    }

    // MARK: Haptics — a felt hierarchy, tuned for restraint (a digital missal,
    // not a game). Soft thumb-tick per bead; weightier at the milestones.
    private func haptic(for step: RosaryStep, finished: Bool) -> SensoryFeedback? {
        if finished { return .success }                                  // whole rosary done
        if step.closesDecade { return .impact(weight: .heavy) }          // decade complete
        if (1...5).contains(step.phase), step.isLargeBead,
           step.prayer == RosaryPrayers.ourFather {
            return .impact(weight: .medium, intensity: 0.6)              // new mystery begins
        }
        return .impact(flexibility: .soft, intensity: 0.5)               // a bead under the thumb
    }

    private func circleButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16))
                .foregroundStyle(t.inkMid)
                .frame(width: 48, height: 48)
                .background(t.surface, in: .circle)
                .overlay(Circle().strokeBorder(t.rule, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Full rosary sheet

private struct FullRosarySheet: View {
    let vm: RosaryViewModel
    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Eyebrow(text: vm.mystery.displayName, color: pal.accent)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundStyle(t.inkMid)
                        .frame(width: 32, height: 32)
                        .background(t.surface, in: .circle)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            Text("The Holy Rosary")
                .font(LumenType.display(24))
                .foregroundStyle(t.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 4)

            ScrollView {
                FlowLayout(spacing: 5, lineSpacing: 7) {
                    ForEach(0..<vm.count, id: \.self) { i in
                        let step = vm.steps[i]
                        let isCurrent = i == vm.index
                        let isPast = i < vm.index
                        Button { vm.setIndex(i); dismiss() } label: {
                            Circle()
                                .fill(isCurrent ? pal.accent : (isPast ? pal.accentSoft : t.surface3))
                                .frame(width: step.isLargeBead ? 13 : 9,
                                       height: step.isLargeBead ? 13 : 9)
                                .overlay(Circle().strokeBorder(isCurrent ? pal.accent : t.rule, lineWidth: 0.5))
                                .frame(width: 22, height: 22)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationBackground(t.bg)
    }
}

#Preview {
    RosaryView()
        .environment(\.lumenTokens, .parchment)
        .environment(\.lumenPalette, .for(.lent))
        .modelContainer(PreviewSupport.container)
}
