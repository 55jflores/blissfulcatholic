//
//  LumenTabBar.swift
//  Blissful Catholic
//
//  The floating, frosted, hairline-bordered tab bar from the Lumen design.
//  Sits above content; the active tab takes the liturgical accent + a glow dot.
//

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case daily, pray, learn, journal, profile
    var id: String { rawValue }

    var label: String {
        switch self {
        case .daily:   return "Daily"
        case .pray:    return "Pray"
        case .learn:   return "Learn"
        case .journal: return "Journal"
        case .profile: return "You"
        }
    }
    var systemImage: String {
        switch self {
        case .daily:   return "sun.max"
        case .pray:    return "hands.and.sparkles"
        case .learn:   return "book.closed"
        case .journal: return "square.and.pencil"
        case .profile: return "person"
        }
    }
}

struct LumenTabBar: View {
    @Binding var selection: AppTab
    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                let isActive = selection == tab
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 20, weight: isActive ? .semibold : .regular))
                                .offset(y: isActive ? -1 : 0)
                            if isActive {
                                Circle()
                                    .fill(pal.accent)
                                    .frame(width: 4, height: 4)
                                    .shadow(color: pal.accent, radius: 4)
                                    .offset(y: 14)
                            }
                        }
                        .frame(height: 24)
                        Text(tab.label)
                            .font(LumenType.ui(9.5, weight: isActive ? .semibold : .medium))
                            .textCase(.uppercase)
                            .tracking(0.6)
                    }
                    .foregroundStyle(isActive ? pal.accent : t.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: selection)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(t.rule, lineWidth: 0.5))
        .shadow(color: Color(hex: 0x3c2612, alpha: 0.18), radius: 14, y: 12)
        .padding(.horizontal, 12)
    }
}
