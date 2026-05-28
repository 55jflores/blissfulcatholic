//
//  LumenScreenHeader.swift
//  Blissful Catholic
//
//  The soft sticky header used across tabs: a thin liturgical accent bar (the
//  ribbon bookmark of a missal), an eyebrow, and a large Cormorant-style title.
//

import SwiftUI

struct LumenScreenHeader<Right: View>: View {
    let eyebrow: String
    let title: String
    @ViewBuilder var right: () -> Right

    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(pal.accent.opacity(0.7))
                .frame(height: 3)
                .padding(.bottom, 18)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: eyebrow, color: pal.accent)
                    Text(title)
                        .font(LumenType.display(38))
                        .foregroundStyle(t.ink)
                        .tracking(-0.4)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                right()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }
}

extension LumenScreenHeader where Right == EmptyView {
    init(eyebrow: String, title: String) {
        self.init(eyebrow: eyebrow, title: title, right: { EmptyView() })
    }
}

/// Small circular icon button used in headers.
struct LumenIconButton: View {
    let systemImage: String
    var action: () -> Void = {}

    @Environment(\.lumenTokens) private var t

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(t.inkMid)
                .frame(width: 36, height: 36)
                .background(t.surface, in: .circle)
                .overlay(Circle().strokeBorder(t.rule, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}
