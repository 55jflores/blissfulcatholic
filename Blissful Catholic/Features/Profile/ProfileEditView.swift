//
//  ProfileEditView.swift
//  Blissful Catholic
//
//  Edit identity — name, Catholic background, state in life, faith maturity.
//  Reskinned to Lumen. Edits a working copy; commits to UserProfileStore on Save.
//

import SwiftUI

struct ProfileEditView: View {
    @Environment(UserProfileStore.self) private var profile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal

    @State private var name = ""
    @State private var background: CatholicBackground?
    @State private var stateInLife: StateInLife?
    @State private var faithMaturity: FaithMaturity?
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    labeled("Your name") {
                        TextField("", text: $name, prompt: Text("Friend in Christ").foregroundStyle(t.inkSoft))
                            .font(LumenType.serif(16))
                            .foregroundStyle(t.ink)
                            .textInputAutocapitalization(.words)
                            .padding(16)
                            .background(t.surface, in: .rect(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(t.rule, lineWidth: 0.5))
                    }
                    labeled("How you came to the faith") {
                        LumenChoiceList(options: CatholicBackground.allCases, selection: $background,
                                        label: \.displayName, detail: \.detail)
                    }
                    labeled("State in life") {
                        LumenChoiceList(options: StateInLife.allCases, selection: $stateInLife,
                                        label: \.displayName)
                    }
                    labeled("Where you are on the journey") {
                        LumenChoiceList(options: FaithMaturity.allCases, selection: $faithMaturity,
                                        label: \.displayName, detail: \.detail)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .background(t.bg.ignoresSafeArea())
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.tint(t.inkMid)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.tint(pal.accent).fontWeight(.semibold)
                }
            }
            .onAppear(perform: loadOnce)
        }
    }

    @ViewBuilder
    private func labeled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: title, color: t.inkSoft)
            content()
        }
    }

    private func loadOnce() {
        guard !loaded else { return }
        name = profile.displayName
        background = profile.background
        stateInLife = profile.stateInLife
        faithMaturity = profile.faithMaturity
        loaded = true
    }

    private func save() {
        profile.displayName = name
        profile.background = background
        profile.stateInLife = stateInLife
        profile.faithMaturity = faithMaturity
        dismiss()
    }
}

#Preview {
    ProfileEditView()
        .environment(UserProfileStore.preview)
        .environment(\.lumenTokens, .parchment)
        .environment(\.lumenPalette, .for(.easter))
}
