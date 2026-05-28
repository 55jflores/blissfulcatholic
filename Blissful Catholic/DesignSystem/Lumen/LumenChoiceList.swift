//
//  LumenChoiceList.swift
//  Blissful Catholic
//
//  A single-select list of options in the Lumen style. Shared by onboarding and
//  the profile editor so they stay visually identical.
//

import SwiftUI

struct LumenChoiceList<Option: Identifiable & Hashable>: View {
    let options: [Option]
    @Binding var selection: Option?
    let label: (Option) -> String
    let detail: ((Option) -> String)?

    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal

    init(options: [Option], selection: Binding<Option?>,
         label: KeyPath<Option, String>, detail: KeyPath<Option, String>? = nil) {
        self.options = options
        self._selection = selection
        self.label = { $0[keyPath: label] }
        self.detail = detail.map { kp in { $0[keyPath: kp] } }
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(options) { option in
                let isSelected = selection == option
                Button { selection = option } label: {
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(label(option))
                                .font(LumenType.display(18))
                                .foregroundStyle(t.ink)
                            if let detail {
                                Text(detail(option))
                                    .font(LumenType.serif(12))
                                    .foregroundStyle(t.inkMid)
                            }
                        }
                        Spacer(minLength: 0)
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected ? pal.accent : t.inkSoft)
                    }
                    .padding(16)
                    .background(t.surface, in: .rect(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isSelected ? pal.accent : t.rule, lineWidth: isSelected ? 1.5 : 0.5))
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: isSelected)
            }
        }
    }
}

/// A primary, accent-filled pill button in the Lumen style.
struct LumenPrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void
    @Environment(\.lumenPalette) private var pal

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).font(LumenType.ui(14, weight: .medium))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(pal.accent, in: .capsule)
        }
        .buttonStyle(.plain)
    }
}
