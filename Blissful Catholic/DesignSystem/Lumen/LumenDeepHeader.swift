//
//  LumenDeepHeader.swift
//  Blissful Catholic
//
//  The sub-header shared by deep (pushed) screens: a back button, a centered
//  eyebrow + title, and an optional trailing slot.
//

import SwiftUI

struct LumenDeepHeader<Right: View>: View {
    let eyebrow: String
    let title: String
    var onBack: () -> Void
    @ViewBuilder var right: () -> Right

    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(t.inkMid)
                    .frame(width: 36, height: 36)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)

            VStack(spacing: 2) {
                Eyebrow(text: eyebrow, color: pal.accent)
                Text(title)
                    .font(LumenType.display(17))
                    .foregroundStyle(t.ink)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            right().frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) { Rectangle().fill(t.ruleSoft).frame(height: 0.5) }
        .background(t.bg)
    }
}

extension LumenDeepHeader where Right == EmptyView {
    init(eyebrow: String, title: String, onBack: @escaping () -> Void) {
        self.init(eyebrow: eyebrow, title: title, onBack: onBack, right: { EmptyView() })
    }
}
