//
//  AudioPlayer.swift
//  Blissful Catholic
//
//  The app's single podcast playback engine: an @Observable wrapper around
//  AVPlayer that streams an episode's enclosure URL verbatim (preserving the
//  feed's measurement prefix so the podcaster gets the download).
//
//  Background-capable: with the `audio` UIBackgroundModes entry + the .playback
//  session, audio keeps playing when the screen locks or the app is backgrounded.
//  It also publishes lock-screen / Control Center / AirPods controls via
//  MPNowPlayingInfoCenter + MPRemoteCommandCenter, and reacts to interruptions
//  (calls, Siri) and route changes (headphones unplugged).
//
//  A shared singleton: one engine for the whole app, set up once.
//

import Foundation
import AVFoundation
import MediaPlayer
import UIKit

@MainActor
@Observable
final class AudioPlayer {
    static let shared = AudioPlayer()

    private(set) var current: Episode?
    private(set) var showTitle = ""
    private(set) var isPlaying = false
    private(set) var currentSeconds: Double = 0
    private(set) var durationSeconds: Double = 0

    /// Playback speed — persisted and applied across episodes (aficionados
    /// expect their speed to stick).
    private(set) var speed: Float = 1.0

    /// The speeds the cycle button steps through.
    static let speeds: [Float] = [1.0, 1.25, 1.5, 1.75, 2.0]
    private static let speedKey = "player.speed"

    private let player = AVPlayer()
    private var timeObserver: Any?

    // Lock-screen artwork, fetched once per show and reused.
    private var artworkURL: URL?
    private var nowPlayingArtwork: MPMediaItemArtwork?

    private init() {
        // .playback = audible on silent AND eligible to continue in the
        // background (paired with the audio UIBackgroundModes entry).
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)

        let saved = UserDefaults.standard.float(forKey: Self.speedKey)
        speed = Self.speeds.contains(saved) ? saved : 1.0
        player.defaultRate = speed   // the rate play() resumes at (iOS 16+)

        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            MainActor.assumeIsolated { self?.tick(time) }
        }

        setupRemoteCommands()
        setupNotifications()
    }

    /// Progress 0...1, safe when the duration isn't known yet.
    var fraction: Double {
        guard durationSeconds > 0 else { return 0 }
        return min(1, max(0, currentSeconds / durationSeconds))
    }

    func isCurrent(_ episode: Episode) -> Bool { current?.id == episode.id }

    /// "1×", "1.5×", "1.25×" — for the cycle button.
    var speedLabel: String {
        speed == speed.rounded() ? "\(Int(speed))×" : "\(String(format: "%g", speed))×"
    }

    // MARK: Transport

    /// Start a fresh episode (or resume it if it's already loaded). `showTitle`
    /// + `artworkURL` feed the lock-screen now-playing card.
    func play(_ episode: Episode, showTitle: String, artworkURL: URL?) {
        if current?.id == episode.id {
            resume()
            return
        }
        current = episode
        self.showTitle = showTitle
        currentSeconds = 0
        durationSeconds = 0
        try? AVAudioSession.sharedInstance().setActive(true)
        let item = AVPlayerItem(url: episode.audioURL)
        item.audioTimePitchAlgorithm = .timeDomain   // natural voice at higher speeds
        player.replaceCurrentItem(with: item)
        player.play()
        isPlaying = true
        applyRate()                                  // also refreshes now-playing
        loadArtworkIfNeeded(artworkURL)
    }

    func togglePlayPause() {
        guard current != nil else { return }
        isPlaying ? pause() : resume()
    }

    /// Seek to a 0...1 position of the current item (the in-app scrubber).
    func seek(toFraction f: Double) {
        guard durationSeconds > 0 else { return }
        seek(toSeconds: f * durationSeconds)
    }

    private func seek(toSeconds s: Double) {
        let clamped = max(0, durationSeconds > 0 ? min(s, durationSeconds) : s)
        player.seek(to: CMTime(seconds: clamped, preferredTimescale: 600))
        currentSeconds = clamped
        updateNowPlayingInfo()
    }

    private func resume() {
        player.play()
        isPlaying = true
        applyRate()
    }

    private func pause() {
        player.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    // MARK: Speed

    /// Step to the next speed in `speeds`, wrapping back to 1×.
    func cycleSpeed() {
        let i = Self.speeds.firstIndex(of: speed) ?? 0
        speed = Self.speeds[(i + 1) % Self.speeds.count]
        UserDefaults.standard.set(speed, forKey: Self.speedKey)
        applyRate()
    }

    private func applyRate() {
        player.defaultRate = speed
        if isPlaying { player.rate = speed }   // setting rate while playing changes speed live
        updateNowPlayingInfo()
    }

    private func tick(_ time: CMTime) {
        currentSeconds = time.seconds.isFinite ? time.seconds : 0
        if let d = player.currentItem?.duration.seconds, d.isFinite, d != durationSeconds {
            durationSeconds = d
            updateNowPlayingInfo()   // duration just became known
        }
    }

    // MARK: Now Playing (lock screen / Control Center)

    private func updateNowPlayingInfo() {
        guard let current else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: current.title,
            MPMediaItemPropertyArtist: showTitle,
            MPMediaItemPropertyPlaybackDuration: durationSeconds,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentSeconds,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? Double(speed) : 0.0,
        ]
        if let nowPlayingArtwork { info[MPMediaItemPropertyArtwork] = nowPlayingArtwork }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func loadArtworkIfNeeded(_ url: URL?) {
        guard let url, url != artworkURL else { return }
        artworkURL = url
        nowPlayingArtwork = nil
        Task { @MainActor [weak self] in
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let self, self.artworkURL == url, let image = UIImage(data: data) else { return }
            self.nowPlayingArtwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            self.updateNowPlayingInfo()
        }
    }

    // MARK: Remote commands (lock screen / AirPods / CarPlay)

    private func setupRemoteCommands() {
        let c = MPRemoteCommandCenter.shared()

        c.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resume() }
            return .success
        }
        c.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
        c.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlayPause() }
            return .success
        }

        c.skipForwardCommand.preferredIntervals = [30]
        c.skipForwardCommand.addTarget { [weak self] event in
            let by = (event as? MPSkipIntervalCommandEvent)?.interval ?? 30
            Task { @MainActor in
                guard let self else { return }
                self.seek(toSeconds: self.currentSeconds + by)
            }
            return .success
        }
        c.skipBackwardCommand.preferredIntervals = [15]
        c.skipBackwardCommand.addTarget { [weak self] event in
            let by = (event as? MPSkipIntervalCommandEvent)?.interval ?? 15
            Task { @MainActor in
                guard let self else { return }
                self.seek(toSeconds: self.currentSeconds - by)
            }
            return .success
        }

        c.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let pos = e.positionTime
            Task { @MainActor in self?.seek(toSeconds: pos) }
            return .success
        }
    }

    // MARK: Interruptions + route changes

    private func setupNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            guard let info = note.userInfo,
                  let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
            let optionsRaw = info[AVAudioSessionInterruptionOptionKey] as? UInt
            Task { @MainActor in self?.handleInterruption(type: type, optionsRaw: optionsRaw) }
        }
        nc.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
            guard let info = note.userInfo,
                  let raw = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: raw) else { return }
            Task { @MainActor in self?.handleRouteChange(reason: reason) }
        }
    }

    private func handleInterruption(type: AVAudioSession.InterruptionType, optionsRaw: UInt?) {
        switch type {
        case .began:
            pause()                                  // a call / Siri took the audio
        case .ended:
            if let optionsRaw,
               AVAudioSession.InterruptionOptions(rawValue: optionsRaw).contains(.shouldResume) {
                resume()                             // the system says we may resume
            }
        @unknown default:
            break
        }
    }

    private func handleRouteChange(reason: AVAudioSession.RouteChangeReason) {
        // Headphones unplugged / Bluetooth dropped — pause so it doesn't blast
        // out of the speaker.
        if reason == .oldDeviceUnavailable { pause() }
    }
}
