//
//  OnboardingView.swift
//  Blissful Catholic
//
//  Five warm onboarding screens — welcome, Catholic background, state in life,
//  faith maturity, ready — reskinned to Lumen. Finishing commits answers to the
//  shared UserProfileStore and flips onboardingComplete.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(UserProfileStore.self) private var profile
    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal
    @State private var model = OnboardingViewModel()

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()
            candleGlow

            VStack(spacing: 24) {
                progressBar
                    .padding(.top, 8)

                Spacer(minLength: 0)

                stepContent
                    .frame(maxWidth: .infinity)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)))
                    .id(model.step)

                Spacer(minLength: 0)

                controls
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .animation(.easeInOut(duration: 0.3), value: model.step)
    }

    // MARK: Steps

    @ViewBuilder
    private var stepContent: some View {
        switch model.step {
        case .welcome:
            WelcomeStep()
        case .name:
            NameStep(name: $model.name)
        case .background:
            ChoiceStep(title: "How did you come to the faith?",
                       subtitle: "This helps us meet you where you are.",
                       options: CatholicBackground.allCases,
                       selection: $model.background,
                       label: \.displayName, detail: \.detail)
        case .stateInLife:
            ChoiceStep(title: "What is your state in life?",
                       subtitle: "We'll tailor prayer and formation to your vocation.",
                       options: StateInLife.allCases,
                       selection: $model.stateInLife,
                       label: \.displayName, detail: nil)
        case .faithMaturity:
            ChoiceStep(title: "Where are you on the journey?",
                       subtitle: "There's no wrong answer — only a starting point.",
                       options: FaithMaturity.allCases,
                       selection: $model.faithMaturity,
                       label: \.displayName, detail: \.detail)
        case .ready:
            ReadyStep(model: model)
        }
    }

    // MARK: Chrome

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(t.surface3)
                Capsule().fill(pal.accent)
                    .frame(width: max(8, geo.size.width * model.progress))
            }
        }
        .frame(height: 4)
    }

    private var controls: some View {
        VStack(spacing: 14) {
            LumenPrimaryButton(title: model.isLastStep ? "Begin" : "Continue") {
                if model.isLastStep { finish() } else { model.advance() }
            }
            .opacity(model.canAdvance ? 1 : 0.4)
            .disabled(!model.canAdvance)

            if !model.isFirstStep {
                Button("Back") { model.back() }
                    .font(LumenType.ui(13))
                    .foregroundStyle(t.inkMid)
            }
        }
    }

    private var candleGlow: some View {
        RadialGradient(colors: [pal.accent.opacity(0.18), .clear],
                       center: .top, startRadius: 0, endRadius: 420)
        .ignoresSafeArea()
    }

    private func finish() {
        profile.applyOnboarding(displayName: model.name.trimmingCharacters(in: .whitespaces),
                                background: model.background,
                                stateInLife: model.stateInLife,
                                faithMaturity: model.faithMaturity)
    }
}

// MARK: - Name

private struct NameStep: View {
    @Binding var name: String
    @Environment(\.lumenTokens) private var t
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("What should we call you?")
                    .font(LumenType.display(28))
                    .foregroundStyle(t.ink)
                Text("We'll greet you by name and make your journey your own.")
                    .font(LumenType.serif(14))
                    .foregroundStyle(t.inkMid)
            }
            TextField("", text: $name, prompt: Text("Your name").foregroundStyle(t.inkSoft))
                .font(LumenType.display(22))
                .foregroundStyle(t.ink)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .focused($focused)
                .padding(16)
                .background(t.surface, in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(t.rule, lineWidth: 0.5))
        }
        .onAppear { focused = true }
    }
}

// MARK: - Welcome

private struct WelcomeStep: View {
    @Environment(\.lumenTokens) private var t
    var body: some View {
        VStack(spacing: 24) {
            Candle(size: 56, lit: true)
            VStack(spacing: 8) {
                Text("Blissful Catholic")
                    .font(LumenType.display(38))
                    .foregroundStyle(t.ink)
                Text("Walk with joy every day.")
                    .font(LumenType.display(20).italic())
                    .foregroundStyle(t.inkMid)
            }
            .multilineTextAlignment(.center)

            Ornament(color: t.inkSoft).padding(.horizontal, 48)

            Text("A living companion for your Catholic faith — prayer, formation, and reflection that grows with you.")
                .font(LumenType.serif(15))
                .foregroundStyle(t.inkMid)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 16)
        }
    }
}

// MARK: - Choice step

private struct ChoiceStep<Option: Identifiable & Hashable>: View {
    let title: String
    let subtitle: String
    let options: [Option]
    @Binding var selection: Option?
    let label: KeyPath<Option, String>
    let detail: KeyPath<Option, String>?

    @Environment(\.lumenTokens) private var t

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(LumenType.display(28))
                    .foregroundStyle(t.ink)
                Text(subtitle)
                    .font(LumenType.serif(14))
                    .foregroundStyle(t.inkMid)
            }
            LumenChoiceList(options: options, selection: $selection, label: label, detail: detail)
        }
    }
}

// MARK: - Ready

private struct ReadyStep: View {
    let model: OnboardingViewModel
    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(pal.accent)

            VStack(spacing: 8) {
                Text(readyTitle)
                    .font(LumenType.display(28))
                    .foregroundStyle(t.ink)
                Text("We've prepared a path made for you. Let's begin walking it together.")
                    .font(LumenType.serif(14))
                    .foregroundStyle(t.inkMid)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 8) {
                if let b = model.background { summaryRow("Background", b.displayName) }
                if let s = model.stateInLife { summaryRow("State in life", s.displayName) }
                if let f = model.faithMaturity { summaryRow("Journey", f.displayName) }
            }
        }
    }

    private var readyTitle: String {
        let first = model.name.trimmingCharacters(in: .whitespaces).split(separator: " ").first.map(String.init)
        return first.map { "You're all set, \($0)" } ?? "You're all set"
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(LumenType.ui(12)).foregroundStyle(t.inkSoft)
            Spacer()
            Text(value).font(LumenType.display(17)).foregroundStyle(t.ink)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(t.surface, in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(t.rule, lineWidth: 0.5))
    }
}

#Preview {
    OnboardingView()
        .environment(UserProfileStore.preview)
        .environment(\.lumenTokens, .parchment)
        .environment(\.lumenPalette, .for(.easter))
}
