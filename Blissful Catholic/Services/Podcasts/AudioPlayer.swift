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

enum SleepMode: Equatable {
    case off
    case timed(until: Date)
    case endOfEpisode
}

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

    // Resume bookkeeping: throttle how often we persist the current position.
    private var lastSavedSecond: Double = 0

    // Sleep timer (session-only; not persisted).
    private(set) var sleepMode: SleepMode = .off
    private(set) var sleepRemaining: TimeInterval = 0   // seconds left, for the countdown badge
    private var sleepTask: Task<Void, Never>?
    private static let sleepFadeSeconds: Double = 15    // gentle volume ramp at the end

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
        saveProgress()                               // persist where we were in the outgoing episode

        current = episode
        self.showTitle = showTitle
        durationSeconds = 0

        // Resume mid-episode if we have a saved, unfinished position.
        let saved = PodcastProgressStore.position(for: episode.id)
        let resumeAt = (saved.map { !$0.isFinished && $0.seconds > 3 } ?? false) ? saved!.seconds : 0
        currentSeconds = resumeAt
        lastSavedSecond = resumeAt

        try? AVAudioSession.sharedInstance().setActive(true)
        let item = AVPlayerItem(url: episode.audioURL)
        item.audioTimePitchAlgorithm = .timeDomain   // natural voice at higher speeds
        player.replaceCurrentItem(with: item)
        if resumeAt > 0 {
            player.seek(to: CMTime(seconds: resumeAt, preferredTimescale: 600))
        }
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
        saveProgress()
        updateNowPlayingInfo()
    }

    // MARK: Resume position

    /// Persist the current spot for the current episode (no-op until we know the
    /// duration / have made progress).
    private func saveProgress() {
        guard let current, durationSeconds > 0, currentSeconds > 1 else { return }
        PodcastProgressStore.save(id: current.id, seconds: currentSeconds, duration: durationSeconds)
        lastSavedSecond = currentSeconds
    }

    /// Episode reached the end — clear its resume pointer so it restarts fresh,
    /// and reflect the finished state.
    private func handlePlaybackEnded() {
        if let current { PodcastProgressStore.clear(id: current.id) }
        isPlaying = false
        currentSeconds = durationSeconds
        lastSavedSecond = 0
        if sleepMode == .endOfEpisode { cancelSleepTimer() }   // its job is done
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

    // MARK: Sleep timer

    var sleepActive: Bool { sleepMode != .off }

    /// Countdown badge text: "14:59" while timed, "End" for end-of-episode.
    var sleepLabel: String {
        switch sleepMode {
        case .off:          return ""
        case .endOfEpisode: return "End"
        case .timed:
            let s = Int(sleepRemaining.rounded())
            return String(format: "%d:%02d", s / 60, s % 60)
        }
    }

    func startSleepTimer(minutes: Int) {
        player.volume = 1.0
        sleepRemaining = Double(minutes) * 60
        sleepMode = .timed(until: Date().addingTimeInterval(sleepRemaining))
        cancelSleepLoop()
        sleepTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.tickSleep()
            }
        }
    }

    /// Stop when the current episode ends (no countdown).
    func sleepAtEndOfEpisode() {
        cancelSleepLoop()
        player.volume = 1.0
        sleepRemaining = 0
        sleepMode = .endOfEpisode
    }

    func cancelSleepTimer() {
        cancelSleepLoop()
        sleepMode = .off
        sleepRemaining = 0
        player.volume = 1.0
    }

    private func cancelSleepLoop() {
        sleepTask?.cancel()
        sleepTask = nil
    }

    private func tickSleep() {
        guard case .timed(let until) = sleepMode else { return }
        let remaining = until.timeIntervalSinceNow
        if remaining <= 0 {
            cancelSleepTimer()   // resets volume to 1.0 for the next play
            pause()
        } else {
            sleepRemaining = remaining
            // Gentle fade over the final stretch instead of a hard cut.
            player.volume = remaining < Self.sleepFadeSeconds
                ? Float(max(0, remaining / Self.sleepFadeSeconds)) : 1.0
        }
    }

    private func tick(_ time: CMTime) {
        currentSeconds = time.seconds.isFinite ? time.seconds : 0
        if let d = player.currentItem?.duration.seconds, d.isFinite, d != durationSeconds {
            durationSeconds = d
            updateNowPlayingInfo()   // duration just became known
        }
        // Persist roughly every 5s of playback so a crash/kill loses little.
        if isPlaying, abs(currentSeconds - lastSavedSecond) >= 5 {
            saveProgress()
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
        nc.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.handlePlaybackEnded() }
        }
        // Capture the latest position when the app is backgrounded or killed.
        nc.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.saveProgress() }
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
