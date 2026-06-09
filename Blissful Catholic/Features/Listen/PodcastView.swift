//
//  PodcastView.swift
//  Blissful Catholic
//
//  The single-podcast simulation screen (docs/podcast-flow.md): loads one
//  curated feed, shows its artwork + episode list, and streams a tapped episode
//  through a docked PlayerBar. A deliberately small "full pass" to prove the
//  flow before the real multi-podcast Listen feature.
//

import SwiftUI

struct PodcastView: View {
    @Environment(\.lumenTokens) private var t
    @Environment(\.lumenPalette) private var pal
    @Environment(\.dismiss) private var dismiss

    @State private var store = PodcastStore()
    private let player = AudioPlayer.shared

    var feed: PodcastFeed = PodcastSeed.bibleInAYear

    var body: some View {
        ZStack(alignment: .bottom) {
            t.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                LumenDeepHeader(eyebrow: "Listen", title: "Podcast") { dismiss() }

                if store.isLoading && store.podcast == nil {
                    loadingState
                } else if let podcast = store.podcast {
                    loaded(podcast)
                } else if store.loadFailed {
                    failedState
                } else {
                    Spacer()
                }
            }

            // Float the mini-player just above the parent's floating tab bar
            // (~68pt tall, pinned to the bottom safe area in MainTabView).
            PlayerBar(player: player)
                .padding(.bottom, 84)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await store.load(feed) }
    }

    // MARK: States

    private var loadingState: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView().tint(pal.accent)
            Text("Loading episodes…")
                .font(LumenType.serif(14).italic())
                .foregroundStyle(t.inkSoft)
            Spacer()
        }
    }

    private var failedState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "wifi.slash")
                .font(.system(size: 26))
                .foregroundStyle(t.inkSoft)
            Text("Couldn't load this podcast.")
                .font(LumenType.serif(15).italic())
                .foregroundStyle(t.inkMid)
            Button("Try again") { Task { await store.load(feed) } }
                .font(LumenType.ui(12, weight: .medium))
                .foregroundStyle(pal.accent)
            Spacer()
        }
    }

    // MARK: Loaded content

    private func loaded(_ podcast: Podcast) -> some View {
        ScrollView {
            // Lazy: only the visible rows are built, so the list stays cheap as
            // this year's run grows from ~166 today toward ~370 by December.
            LazyVStack(alignment: .leading, spacing: 0) {
                channelHeader(podcast)
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 14)

                Ornament(color: pal.accent)
                    .frame(maxWidth: 180)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 6)

                ForEach(podcast.episodes) { episode in
                    episodeRow(episode)
                    Rectangle().fill(t.ruleSoft).frame(height: 0.5)
                        .padding(.leading, 20)
                }
            }
            // Clear the floating tab bar (always) plus the docked PlayerBar
            // (when an episode is loaded) so the last row isn't hidden.
            .padding(.bottom, player.current == nil ? 110 : 190)
        }
    }

    private func channelHeader(_ podcast: Podcast) -> some View {
        HStack(alignment: .top, spacing: 14) {
            AsyncImage(url: podcast.artworkURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                t.surface3
            }
            .frame(width: 84, height: 84)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(t.rule, lineWidth: 0.5))

            VStack(alignment: .leading, spacing: 5) {
                Text(podcast.title)
                    .font(LumenType.display(20))
                    .foregroundStyle(t.ink)
                    .lineLimit(3)
                Text(podcast.author)
                    .font(LumenType.ui(12))
                    .foregroundStyle(t.inkSoft)
            }
            Spacer(minLength: 0)
        }
    }

    private func episodeRow(_ episode: Episode) -> some View {
        Button {
            player.play(episode,
                        showTitle: store.podcast?.title ?? feed.name,
                        artworkURL: store.podcast?.artworkURL)
        } label: {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: playIcon(episode))
                    .font(.system(size: 15))
                    .foregroundStyle(pal.accent)
                    .frame(width: 38, height: 38)
                    .background(t.surface3, in: .circle)
                    .overlay(Circle().strokeBorder(t.rule, lineWidth: 0.5))

                VStack(alignment: .leading, spacing: 5) {
                    Text(episode.title)
                        .font(LumenType.serif(15))
                        .foregroundStyle(t.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    let progress = rowProgress(episode)
                    Text(metaLine(episode, progress: progress))
                        .font(LumenType.ui(10))
                        .tracking(0.3)
                        .foregroundStyle(progress == nil ? t.inkSoft : pal.accent)

                    if let progress {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(t.surface3).frame(height: 3)
                                Capsule().fill(pal.accent)
                                    .frame(width: geo.size.width * progress.fraction, height: 3)
                            }
                        }
                        .frame(height: 3)
                        .padding(.top, 1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func playIcon(_ episode: Episode) -> String {
        if player.isCurrent(episode) {
            return player.isPlaying ? "waveform" : "play.fill"
        }
        return "play.fill"
    }

    private func metaLine(_ episode: Episode, progress: (fraction: Double, remaining: Double)?) -> String {
        var parts = [episode.durationLabel, episode.dateLabel].filter { !$0.isEmpty }
        if let progress {
            let mins = Int((progress.remaining / 60).rounded(.up))
            parts.append(mins <= 0 ? "almost done" : "\(mins) min left")
        }
        return parts.joined(separator: " · ")
    }

    /// The resume state to show on a row: live position for the playing episode,
    /// otherwise the saved pointer. Nil when there's nothing to resume.
    private func rowProgress(_ episode: Episode) -> (fraction: Double, remaining: Double)? {
        if player.isCurrent(episode), player.durationSeconds > 0 {
            return (player.fraction, max(0, player.durationSeconds - player.currentSeconds))
        }
        if let p = PodcastProgressStore.position(for: episode.id), !p.isFinished, p.fraction > 0.01 {
            return (p.fraction, p.secondsRemaining)
        }
        return nil
    }
}

#Preview {
    NavigationStack {
        PodcastView()
            .environment(\.lumenTokens, .parchment)
            .environment(\.lumenPalette, .for(.ordinaryTime))
    }
}
