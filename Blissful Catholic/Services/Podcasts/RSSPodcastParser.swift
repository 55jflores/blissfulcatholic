//
//  RSSPodcastParser.swift
//  Blissful Catholic
//
//  A minimal, dependency-free RSS → Podcast parser for the single-podcast
//  simulation. Built on Foundation's event-based XMLParser so we don't pull in
//  an SPM package yet; the real feature can swap in FeedKit behind PodcastStore
//  without touching the rest of the flow.
//
//  Handles the subset podcasts actually use: channel title / itunes:author /
//  itunes:image, and per-item title, description|itunes:summary, enclosure,
//  itunes:duration, pubDate, guid. An element stack keeps channel-level tags
//  from being confused with the same-named tags inside <item> or <image>.
//

import Foundation

enum RSSPodcastParser {
    /// Parse synchronously off the main actor. Returns nil only if no playable
    /// episodes were found (a malformed or empty feed). `nonisolated` so it can
    /// run on a background task under the project's main-actor-by-default rule.
    ///
    /// - Parameters:
    ///   - since: keep only episodes published on/after this date (nil = all).
    ///   - maxEpisodes: hard safety bound on how many to keep.
    nonisolated static func parse(_ data: Data, feedName: String,
                                  since: Date? = nil, maxEpisodes: Int = 500) -> Podcast? {
        let delegate = Delegate(since: since, maxEpisodes: maxEpisodes)
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()

        guard !delegate.episodes.isEmpty else { return nil }
        return Podcast(
            title: delegate.channelTitle.isEmpty ? feedName : delegate.channelTitle,
            author: delegate.channelAuthor,
            artworkURL: delegate.channelArtwork.flatMap(URL.init(string:)),
            episodes: delegate.episodes
        )
    }

    // MARK: - Delegate

    private nonisolated final class Delegate: NSObject, XMLParserDelegate {
        let since: Date?
        let maxEpisodes: Int
        init(since: Date?, maxEpisodes: Int) {
            self.since = since
            self.maxEpisodes = maxEpisodes
        }

        // Channel-level
        var channelTitle = ""
        var channelAuthor = ""
        var channelArtwork: String?

        var episodes: [Episode] = []

        // Per-item scratch, reset at each <item>
        private var inItem = false
        private var itemTitle = ""
        private var itemSummary = ""
        private var itemAudio: String?
        private var itemDuration = ""
        private var itemGUID = ""
        private var itemPubDate: Date?

        private var stack: [String] = []
        private var buffer = ""

        // RFC 822 dates, e.g. "Sat, 06 Jun 2026 03:15:00 -0400"
        private let rfc822: DateFormatter = {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
            return f
        }()

        func parser(_ parser: XMLParser, didStartElement element: String,
                    namespaceURI: String?, qualifiedName qName: String?,
                    attributes attrs: [String: String]) {
            let name = qName ?? element
            stack.append(name)
            buffer = ""

            switch name {
            case "item":
                inItem = true
                itemTitle = ""; itemSummary = ""; itemAudio = nil
                itemDuration = ""; itemGUID = ""; itemPubDate = nil
            case "enclosure" where inItem:
                itemAudio = attrs["url"]
            case "itunes:image" where !inItem && channelArtwork == nil:
                channelArtwork = attrs["href"]
            default:
                break
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            buffer += string
        }

        func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
            if let s = String(data: CDATABlock, encoding: .utf8) { buffer += s }
        }

        func parser(_ parser: XMLParser, didEndElement element: String,
                    namespaceURI: String?, qualifiedName qName: String?) {
            let name = qName ?? element
            let text = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
            // Parent element this text belonged to (for channel-vs-item routing).
            let parent = stack.count >= 2 ? stack[stack.count - 2] : ""

            switch name {
            case "item":
                let withinWindow = since.map { cut in (itemPubDate.map { $0 >= cut }) ?? false } ?? true
                if withinWindow, episodes.count < maxEpisodes,
                   let audio = itemAudio, let url = URL(string: audio) {
                    episodes.append(Episode(
                        id: itemGUID.isEmpty ? audio : itemGUID,
                        title: itemTitle,
                        summary: itemSummary,
                        audioURL: url,
                        duration: itemDuration,
                        publishedAt: itemPubDate))
                }
                // The feed is newest-first, so once we've filled the cap or
                // fallen past the cutoff date, everything below is older/unwanted
                // — stop walking the remaining (potentially thousands of) items.
                if episodes.count >= maxEpisodes {
                    parser.abortParsing()
                } else if let cut = since, let pub = itemPubDate, pub < cut, !episodes.isEmpty {
                    parser.abortParsing()
                }
                inItem = false
            case "title":
                if inItem { itemTitle = text }
                else if parent == "channel" { channelTitle = text }
            case "itunes:author" where parent == "channel":
                channelAuthor = text
            case "description", "itunes:summary":
                if inItem, itemSummary.isEmpty { itemSummary = text }
            case "itunes:duration" where inItem:
                itemDuration = text
            case "guid" where inItem:
                itemGUID = text
            case "pubDate" where inItem:
                itemPubDate = rfc822.date(from: text)
            default:
                break
            }

            if !stack.isEmpty { stack.removeLast() }
            buffer = ""
        }
    }
}
