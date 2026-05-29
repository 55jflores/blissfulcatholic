//
//  PlusUpsellCard.swift
//  Blissful Catholic
//
//  Shown when a Plus-only AI feature returns `upgrade_required` (403). A soft
//  upsell for now — real purchases arrive with RevenueCat in Phase 5.
//

import SwiftUI

struct PlusUpsellCard: View {
    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal

    var body: some View {
        LumenCard(padding: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "Blissful Catholic Plus", color: pal.accent)
                Text("Unlimited companionship")
                    .font(LumenType.display(18)).foregroundStyle(t.ink)
                Text("Lectio Divina, asking the Catechism, confession preparation, journal insights, and the lives of the saints are part of Plus. (Coming soon.)")
                    .font(LumenType.serif(14))
                    .foregroundStyle(t.inkMid)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
