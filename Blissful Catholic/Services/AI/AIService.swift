//
//  AIService.swift
//  Blissful Catholic
//
//  Calls the Next.js AI proxy (iOS → blissfulcatholic.com → Claude) and streams
//  the reply back as text deltas. The proxy enforces auth, entitlement, and rate
//  limits server-side; here we just send the JWT and parse the SSE stream.
//

import Foundation

enum AIError: LocalizedError {
    case notSignedIn
    case upgradeRequired
    case rateLimited
    case server(String)

    var errorDescription: String? {
        switch self {
        case .notSignedIn:    return "Please sign in to continue."
        case .upgradeRequired: return "This is part of Blissful Catholic Plus."
        case .rateLimited:    return "You've reached today's limit. Please try again later."
        case .server(let m):  return m
        }
    }
}

struct AIService {
    static let shared = AIService()
    private let endpoint = SupabaseConfig.apiBaseURL.appending(path: "api/ai")

    /// Streams the assistant's reply as text deltas. The caller supplies a fresh
    /// access token (from `AuthStore.accessToken()`).
    func stream(
        feature: String,
        messages: [[String: String]],
        personalization: String?,
        token: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = URLRequest(url: endpoint)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

                    var body: [String: Any] = ["feature": feature, "messages": messages]
                    if let personalization { body["personalization"] = personalization }
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        throw AIError.server("No response from server.")
                    }

                    // Non-200 → the proxy returns a JSON error body.
                    guard http.statusCode == 200 else {
                        var data = Data()
                        for try await byte in bytes { data.append(byte) }
                        let code = (try? JSONSerialization.jsonObject(with: data)
                            as? [String: Any])?["error"] as? String
                        switch http.statusCode {
                        case 401: throw AIError.notSignedIn
                        case 403: throw AIError.upgradeRequired
                        case 429: throw AIError.rateLimited
                        default:  throw AIError.server(code ?? "Something went wrong (\(http.statusCode)).")
                        }
                    }

                    // 200 → Server-Sent Events: lines of `data: {json}`.
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: "),
                              let json = line.dropFirst(6).data(using: .utf8),
                              let obj = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
                              let type = obj["type"] as? String
                        else { continue }

                        switch type {
                        case "text":
                            if let chunk = obj["text"] as? String { continuation.yield(chunk) }
                        case "done":
                            continuation.finish()
                            return
                        case "error":
                            throw AIError.server(obj["message"] as? String ?? "Stream error.")
                        default:
                            break
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
