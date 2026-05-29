//
//  AICTAButton.swift
//  Blissful Catholic
//
//  The gradient "tap to open an AI companion" call-to-action, shared across the
//  Daily, Learn, reading, and saint surfaces.
//

import SwiftUI

struct AICTAButton: View {
    let title: String
    let subtitle: String
    var action: () -> Void

    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles").font(.system(size: 16))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(LumenType.ui(14, weight: .medium))
                    Text(subtitle)
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
}
