//
//  LumenType.swift
//  Blissful Catholic
//
//  Lumen's type, approximated with system fonts (per the locked decision):
//  • Cormorant Garamond / Newsreader  → New York  (Font design: .serif)
//  • Geist                            → SF Pro    (Font design: .default)
//  • Geist Mono                       → SF Mono   (Font design: .monospaced)
//
//  Helpers take explicit point sizes so we can match the design's measurements.
//  Swapping in the real bundled fonts later is a localized change here.
//

import SwiftUI

enum LumenType {
    /// Display serif (Cormorant Garamond) — headers, titles, pull-quotes.
    static func display(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    /// Body serif (Newsreader) — reading text, previews.
    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    /// UI sans (Geist) — labels, buttons, metadata.
    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    /// Monospace (Geist Mono) — tiny tracked captions.
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension View {
    /// The "eyebrow" treatment: small, uppercase, tracked sans label.
    func eyebrowStyle() -> some View {
        self.font(LumenType.ui(10, weight: .semibold))
            .textCase(.uppercase)
            .tracking(1.4)
    }
}
