//
//  LumenAtoms.swift
//  Blissful Catholic
//
//  The shared building blocks of the Lumen look: the eyebrow label, the diamond
//  ornament divider, the card surface, the painted "ArtPlate" portrait, and the
//  animated candle.
//

import SwiftUI

// ── Eyebrow ──────────────────────────────────────────────────────────────────
struct Eyebrow: View {
    let text: String
    var color: Color

    var body: some View {
        Text(text)
            .eyebrowStyle()
            .foregroundStyle(color)
    }
}

// ── Ornament ─────────────────────────────────────────────────────────────────
/// A hairline with a small diamond at the center — an illuminated-manuscript rule.
struct Ornament: View {
    var color: Color

    var body: some View {
        HStack(spacing: 8) {
            line
            Diamond()
                .fill(color.opacity(0.8))
                .frame(width: 8, height: 8)
            line
        }
        .opacity(0.5)
    }

    private var line: some View {
        Rectangle().fill(color.opacity(0.4)).frame(height: 1)
    }
}

private struct Diamond: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY))
        p.closeSubpath()
        return p
    }
}

// ── Card ─────────────────────────────────────────────────────────────────────
struct LumenCard<Content: View>: View {
    var padding: CGFloat = 18
    var cornerRadius: CGFloat = 18
    @ViewBuilder var content: () -> Content
    @Environment(\.lumenTokens) private var t

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(t.surface)
            .clipShape(.rect(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(t.rule, lineWidth: 0.5))
            .lumenShadow(t)
    }
}

// ── ArtPlate ─────────────────────────────────────────────────────────────────
/// A softly painted portrait placeholder — a faded fresco with a halo and a
/// monospace label. `hue` is in degrees (matches the design's hue values).
struct ArtPlate: View {
    var label: String? = nil
    var hue: Double = 30
    var width: CGFloat? = nil
    var height: CGFloat = 140
    var vignette: Bool = true
    var cornerRadius: CGFloat = 12

    var body: some View {
        let h = hue / 360
        let light = Color(hue: h, saturation: 0.26, brightness: 0.80)
        let mid   = Color(hue: h, saturation: 0.36, brightness: 0.60)
        let deep  = Color(hue: h, saturation: 0.46, brightness: 0.42)

        ZStack {
            RadialGradient(colors: [light, mid, deep],
                           center: UnitPoint(x: 0.5, y: 0.35),
                           startRadius: 2, endRadius: height)

            // brushwork striations
            LinearGradient(colors: [.white.opacity(0.04), .clear, .black.opacity(0.05)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .blendMode(.overlay)

            // halo
            RadialGradient(colors: [Color(hex: 0xffebb4, alpha: 0.55), .clear],
                           center: UnitPoint(x: 0.5, y: 0.28),
                           startRadius: 0, endRadius: 34)

            if vignette {
                RadialGradient(colors: [.clear, .black.opacity(0.35)],
                               center: .center, startRadius: height * 0.3, endRadius: height * 0.75)
            }

            if let label {
                VStack {
                    Spacer()
                    HStack {
                        Text(label)
                            .font(LumenType.mono(9))
                            .tracking(0.8)
                            .foregroundStyle(Color(hex: 0xffebc8, alpha: 0.7))
                        Spacer()
                    }
                }
                .padding(10)
            }
        }
        .frame(width: width, height: height)
        .frame(maxWidth: width == nil ? .infinity : nil)
        .clipShape(.rect(cornerRadius: cornerRadius))
    }
}

// ── FlowLayout ───────────────────────────────────────────────────────────────
/// Wraps subviews onto multiple rows (for tag/prompt chips).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > maxW, x > 0 { x = 0; y += rowH + lineSpacing; rowH = 0 }
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
        }
        return CGSize(width: maxW.isFinite ? maxW : x, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += rowH + lineSpacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(sz))
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
        }
    }
}

// ── RuledLines ───────────────────────────────────────────────────────────────
/// Evenly spaced horizontal rules, for the ruled-paper look (journal prompt + compose).
struct RuledLines: Shape {
    var spacing: CGFloat = 28
    func path(in rect: CGRect) -> Path {
        var p = Path()
        var y = rect.minY
        while y <= rect.maxY {
            p.move(to: CGPoint(x: rect.minX, y: y))
            p.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += spacing
        }
        return p
    }
}

// ── Candle ───────────────────────────────────────────────────────────────────
/// A small candle. When `lit`, the flame glows; when `flicker`, it animates.
struct Candle: View {
    var size: CGFloat = 24
    var lit: Bool = true
    var flicker: Bool = true
    @State private var phase = false

    var body: some View {
        let w = size
        let h = size * 1.8

        VStack(spacing: -h * 0.06) {
            // flame
            ZStack {
                if lit {
                    Flame()
                        .fill(RadialGradient(
                            colors: [Color(hex: 0xfff4c0), Color(hex: 0xffb84d), Color(hex: 0xc95a1a, alpha: 0)],
                            center: .center, startRadius: 0, endRadius: w * 0.4))
                    Flame()
                        .fill(Color(hex: 0xfff4c0))
                        .frame(width: w * 0.22, height: h * 0.26)
                }
            }
            .frame(width: w * 0.5, height: h * 0.42)
            .scaleEffect(x: phase ? 1.05 : 0.96, y: phase ? 0.96 : 1.05, anchor: .bottom)
            .shadow(color: lit ? Color(hex: 0xffb84d, alpha: 0.5) : .clear, radius: 6)

            // wax body
            RoundedRectangle(cornerRadius: w * 0.06)
                .fill(Color(hex: 0xf1e4c4))
                .overlay(RoundedRectangle(cornerRadius: w * 0.06)
                    .strokeBorder(Color(hex: 0xc9b48a, alpha: 0.5), lineWidth: 0.5))
                .frame(width: w * 0.42, height: h * 0.56)
        }
        .frame(width: w, height: h)
        .onAppear {
            guard lit, flicker else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                phase = true
            }
        }
    }
}

/// A teardrop flame pointing up.
private struct Flame: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.62),
                       control: CGPoint(x: r.maxX, y: r.minY + h * 0.28))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY),
                       control: CGPoint(x: r.minX + w * 0.86, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.62),
                       control: CGPoint(x: r.minX + w * 0.14, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY),
                       control: CGPoint(x: r.minX, y: r.minY + h * 0.28))
        p.closeSubpath()
        return p
    }
}

#Preview {
    VStack(spacing: 24) {
        Eyebrow(text: "Mass · Friday of the 6th week", color: Color(hex: 0xb8956a))
        Ornament(color: Color(hex: 0x9b876d))
        LumenCard {
            Text("A quiet card").font(LumenType.display(22)).foregroundStyle(Color(hex: 0x2a1f17))
        }
        HStack(spacing: 16) {
            ArtPlate(label: "ST. RITA · 1381", hue: 20, width: 108, height: 130)
            Candle(size: 28, lit: true)
        }
    }
    .padding()
    .background(Color(hex: 0xf4ecdb))
}
