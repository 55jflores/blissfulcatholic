//
//  PlayerBar.swift
//  Blissful Catholic
//
//  The docked mini-player for the podcast simulation: current episode, a
//  play/pause control, and a draggable scrubber. Appears only while an episode
//  is loaded. Lumen-styled to match the deep screens.
//

import SwiftUI

struct PlayerBar: View {
    @Bindable var player: AudioPlayer

    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal

    @State private var scrubbing = false
    @State private var scrubValue: Double = 0

    var body: some View {
        if let episode = player.current {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Button { player.togglePlayPause() } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(pal.accent, in: .circle)
                            .shadow(color: pal.accent.opacity(0.4), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(episode.title)
                            .font(LumenType.ui(13, weight: .medium))
                            .foregroundStyle(t.ink)
                            .lineLimit(1)
                        Text("\(timeLabel(player.currentSeconds)) / \(timeLabel(player.durationSeconds))")
                            .font(LumenType.mono(10))
                            .foregroundStyle(t.inkSoft)
                    }
                    Spacer(minLength: 8)

                    Button { player.cycleSpeed() } label: {
                        Text(player.speedLabel)
                            .font(LumenType.ui(12, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(pal.accent)
                            .frame(minWidth: 42)
                            .padding(.vertical, 7)
                            .background(pal.accent.opacity(0.12), in: .capsule)
                    }
                    .buttonStyle(.plain)
                }

                Slider(value: scrubbing ? $scrubValue : .constant(player.fraction),
                       in: 0...1) { editing in
                    scrubbing = editing
                    if !editing { player.seek(toFraction: scrubValue) }
                }
                .tint(pal.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: .rect(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(t.rule, lineWidth: 0.5))
            .padding(.horizontal, 14)
            // Seed the scrub handle from live progress the moment a drag starts.
            .onChange(of: scrubbing) { _, now in if now { scrubValue = player.fraction } }
        }
    }

    private func timeLabel(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "0:00" }
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
