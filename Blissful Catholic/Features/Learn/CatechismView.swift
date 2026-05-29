//
//  CatechismView.swift
//  Blissful Catholic
//
//  "Ask about the faith" — a Q&A surface backed by the AI proxy's `catechism`
//  feature (teaches with CCC citations). This is the first PLUS-gated AI feature,
//  so it shows three states: signed-out → sign-in; signed-in free → a gentle Plus
//  upsell (the proxy returns 403 upgrade_required); Plus → streamed answer.
//

import SwiftUI

struct CatechismView: View {
    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal
    @Environment(AuthStore.self) private var auth
    @Environment(UserProfileStore.self) private var profile
    @Environment(\.dismiss) private var dismiss

    @State private var question = ""
    @State private var answer = ""
    @State private var phase: Phase = .idle
    @State private var errorText: String?
    @State private var needsPlus = false
    @State private var showSignIn = false
    @FocusState private var fieldFocused: Bool

    private enum Phase { case idle, streaming, done }
    private var trimmed: String { question.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canAsk: Bool { phase != .streaming && trimmed.count >= 3 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if auth.isSignedIn {
                    askField
                    resultArea
                } else {
                    gate
                }
            }
            .padding(24)
        }
        .background(t.bg.ignoresSafeArea())
        .sheet(isPresented: $showSignIn) { SignInView(reason: "Sign in to ask about the faith.") }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: "Ask the Catechism", color: pal.accent)
                Text("Learn the faith").font(LumenType.display(26)).foregroundStyle(t.ink)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(t.inkSoft)
                    .frame(width: 34, height: 34)
                    .background(t.surface, in: .circle)
                    .overlay(Circle().strokeBorder(t.rule, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
        }
    }

    private var askField: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("What is grace? Why do Catholics confess to a priest?",
                      text: $question, axis: .vertical)
                .font(LumenType.serif(15))
                .foregroundStyle(t.ink)
                .lineLimit(1...4)
                .focused($fieldFocused)
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(t.surface, in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(t.rule, lineWidth: 0.5))

            LumenPrimaryButton(title: phase == .streaming ? "…" : "Ask") { ask() }
                .disabled(!canAsk)
                .opacity(canAsk ? 1 : 0.5)
        }
    }

    @ViewBuilder private var resultArea: some View {
        if needsPlus {
            PlusUpsellCard()
        } else if let errorText {
            Text(errorText)
                .font(LumenType.serif(14))
                .foregroundStyle(pal.accent)
                .fixedSize(horizontal: false, vertical: true)
        } else if answer.isEmpty, phase == .streaming {
            HStack(spacing: 8) {
                ProgressView().tint(pal.accent)
                Text("Consulting the Catechism…")
                    .font(LumenType.serif(14).italic()).foregroundStyle(t.inkMid)
            }
        } else if !answer.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(answer)
                    .font(LumenType.serif(17))
                    .foregroundStyle(t.ink)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                if phase == .done { Ornament(color: t.inkSoft).padding(.top, 4) }
            }
        }
    }

    private var gate: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Sign in to ask about the faith.")
                .font(LumenType.serif(15).italic())
                .foregroundStyle(t.inkMid)
            LumenPrimaryButton(title: "Sign in") { showSignIn = true }
        }
        .padding(.top, 4)
    }

    private func ask() {
        let q = trimmed
        fieldFocused = false // dismiss the keyboard
        phase = .streaming
        answer = ""; errorText = nil; needsPlus = false
        Task {
            guard let token = await auth.accessToken() else {
                errorText = AIError.notSignedIn.localizedDescription; phase = .done; return
            }
            let personalization = AppContext.current(profile: profile).systemPromptFragment
            do {
                let stream = AIService.shared.stream(
                    feature: "catechism",
                    messages: [["role": "user", "content": q]],
                    personalization: personalization,
                    token: token
                )
                for try await chunk in stream { answer += chunk }
                phase = .done
            } catch AIError.upgradeRequired {
                needsPlus = true
                phase = .done
            } catch {
                errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                phase = .done
            }
        }
    }
}
