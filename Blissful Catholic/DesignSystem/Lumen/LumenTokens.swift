//
//  LumenTokens.swift
//  Blissful Catholic
//
//  The "Lumen" design language: a digital missal, not a SaaS app. Two grounds —
//  Parchment (light) and Cathedral (dark) — that stay constant while the
//  liturgical accent shifts on top. Tokens mirror the design bundle's
//  lightTokens / darkTokens exactly.
//

import SwiftUI

extension Color {
    /// Hex literal like 0xf4ecdb.
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: alpha)
    }
}

/// Which ground the app is rendered on.
enum ThemeMode: String, CaseIterable, Identifiable, Codable {
    case parchment   // light
    case cathedral   // dark
    case system      // follow iOS appearance
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .parchment: return "Parchment"
        case .cathedral: return "Cathedral"
        case .system:    return "System"
        }
    }
}

/// The ground colors. Accent comes separately from the liturgical palette.
struct LumenTokens: Equatable {
    let bg: Color
    let surface: Color
    let surface2: Color
    let surface3: Color
    let ink: Color
    let inkMid: Color
    let inkSoft: Color
    let gold: Color
    let goldDeep: Color
    let goldGlow: Color

    // Hairlines derive from ink so they read correctly on either ground.
    var rule: Color { ink.opacity(0.10) }
    var ruleSoft: Color { ink.opacity(0.05) }

    // Card shadow — approximated from the design's layered CSS shadow.
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowY: CGFloat

    static let parchment = LumenTokens(
        bg: Color(hex: 0xf4ecdb),
        surface: Color(hex: 0xfbf4e2),
        surface2: Color(hex: 0xf9eed6),
        surface3: Color(hex: 0xefe4cc),
        ink: Color(hex: 0x2a1f17),
        inkMid: Color(hex: 0x6b5847),
        inkSoft: Color(hex: 0x9b876d),
        gold: Color(hex: 0xb8956a),
        goldDeep: Color(hex: 0x8a6d3a),
        goldGlow: Color(hex: 0xb8956a, alpha: 0.18),
        shadowColor: Color(hex: 0x52351d, alpha: 0.10),
        shadowRadius: 10, shadowY: 2)

    static let cathedral = LumenTokens(
        bg: Color(hex: 0x14110d),
        surface: Color(hex: 0x1c1812),
        surface2: Color(hex: 0x221c14),
        surface3: Color(hex: 0x100d0a),
        ink: Color(hex: 0xf0e6d4),
        inkMid: Color(hex: 0xb8a98e),
        inkSoft: Color(hex: 0x7d6f57),
        gold: Color(hex: 0xd6b078),
        goldDeep: Color(hex: 0xb8956a),
        goldGlow: Color(hex: 0xd6b078, alpha: 0.22),
        shadowColor: Color.black.opacity(0.4),
        shadowRadius: 14, shadowY: 8)
}

// ── Environment plumbing ─────────────────────────────────────────────────────
// The resolved tokens & palette are injected once at the root (see
// LumenThemeProvider) so views read them directly without re-resolving.

private struct LumenTokensKey: EnvironmentKey {
    static let defaultValue: LumenTokens = .parchment
}

extension EnvironmentValues {
    var lumenTokens: LumenTokens {
        get { self[LumenTokensKey.self] }
        set { self[LumenTokensKey.self] = newValue }
    }
}

extension View {
    /// Apply the Lumen card shadow for the given tokens.
    func lumenShadow(_ t: LumenTokens) -> some View {
        shadow(color: t.shadowColor, radius: t.shadowRadius, x: 0, y: t.shadowY)
    }
}
