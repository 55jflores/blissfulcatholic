//
//  NotificationRouter.swift
//  Blissful Catholic
//
//  A tiny observable hand-off between a tapped notification and the UI. The
//  notification delegate sets `route`; MainTabView observes it, selects the
//  matching tab, and clears it. Injected at the app root so a cold-launch tap
//  (app not yet running) still routes once the UI appears.
//

import Foundation
import Observation

@MainActor
@Observable
final class NotificationRouter {
    enum Destination: Equatable {
        case daily
    }

    /// Set when a notification is tapped; consumed (and reset to nil) by the UI.
    var route: Destination?
}
