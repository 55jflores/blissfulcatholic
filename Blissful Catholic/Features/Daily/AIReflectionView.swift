//
//  AIReflectionView.swift
//  Blissful Catholic
//
//  The first real iOS → backend → Claude feature. Presented from Daily. Local-first
//  gate: if signed out, it invites sign-in; once signed in, it streams a personalized
//  reflection from the AI proxy (with the user's AppContext as personalization).
//

import SwiftUI

struct AIReflectionView: View {
    let feature: String
    let prompt: String
    var title: String = "A reflection for today"
    var reason: String = "Sign in to receive a reflection shaped for you."

    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal
    @Environment(AuthStore.self) private var auth
    @Environment(UserProfileStore.self) private var profile
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var phase: Phase = .idle
    @State private var errorText: String?
    @State private var showSignIn = false

    private enum Phase { case idle, streaming, done }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if auth.isSignedIn { content } else { gate }
            }
            .padding(24)
        }
        .background(t.bg.ignoresSafeArea())
        .sheet(isPresented: $showSignIn) { SignInView(reason: reason) }
        .task(id: auth.isSignedIn) {
            if auth.isSignedIn, phase == .idle { await run() }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: "Your companion", color: pal.accent)
                Text(title).font(LumenType.display(26)).foregroundStyle(t.ink)
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

    // Signed-in: the streamed reflection.
    @ViewBuilder private var content: some View {
        if let errorText {
            Text(errorText)
                .font(LumenType.serif(14))
                .foregroundStyle(pal.accent)
                .fixedSize(horizontal: false, vertical: true)
        } else if text.isEmpty, phase == .streaming {
            HStack(spacing: 8) {
                ProgressView().tint(pal.accent)
                Text("Reflecting…").font(LumenType.serif(14).italic()).foregroundStyle(t.inkMid)
            }
            .padding(.top, 4)
        } else {
            Text(text)
                .font(LumenType.serif(17))
                .foregroundStyle(t.ink)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }

        if phase == .done, errorText == nil {
            Ornament(color: t.inkSoft).padding(.top, 8)
        }
    }

    // Signed-out: the gentle gate.
    private var gate: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(reason)
                .font(LumenType.serif(15).italic())
                .foregroundStyle(t.inkMid)
                .fixedSize(horizontal: false, vertical: true)
            LumenPrimaryButton(title: "Sign in") { showSignIn = true }
        }
        .padding(.top, 4)
    }

    private func run() async {
        phase = .streaming
        text = ""; errorText = nil
        guard let token = await auth.accessToken() else {
            errorText = AIError.notSignedIn.localizedDescription
            phase = .done
            return
        }
        let personalization = AppContext.current(profile: profile).systemPromptFragment
        do {
            let stream = AIService.shared.stream(
                feature: feature,
                messages: [["role": "user", "content": prompt]],
                personalization: personalization,
                token: token
            )
            for try await chunk in stream { text += chunk }
            phase = .done
        } catch {
            errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            phase = .done
        }
    }
}
