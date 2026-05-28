//
//  RosaryViewModel.swift
//  Blissful Catholic
//
//  Drives one Rosary session: chosen mysteries, the current step, and movement
//  through the complete step list. In-memory for Phase 1; Phase 2 logs completed
//  sessions to SwiftData (RosaryLog), Phase 4 adds AI reflections.
//

import SwiftUI
import Observation

@Observable
final class RosaryViewModel {
    private(set) var mystery: MysterySet
    private(set) var steps: [RosaryStep]
    var index: Int = 0

    init(mystery: MysterySet = .recommended()) {
        self.mystery = mystery
        self.steps = RosaryBuilder.steps(for: mystery)
    }

    var count: Int { steps.count }
    var current: RosaryStep { steps[index] }

    /// The steps belonging to the current movement (opening / a decade / closing),
    /// with their global indices — drives the focused bead row.
    var phaseSteps: [(offset: Int, step: RosaryStep)] {
        steps.enumerated()
            .filter { $0.element.phase == current.phase }
            .map { (offset: $0.offset, step: $0.element) }
    }

    var progress: Double {
        guard count > 1 else { return 0 }
        return Double(index) / Double(count - 1)
    }

    var isFinished: Bool { index >= count - 1 }

    var decadeLabel: String {
        switch current.phase {
        case 1...5: return "Decade \(current.phase) of 5"
        case 6:     return "Closing prayers"
        default:    return "Opening prayers"
        }
    }

    // MARK: Navigation

    @discardableResult
    func advance() -> Bool {
        guard index < count - 1 else { return false }
        index += 1
        return true
    }

    func back() { index = max(0, index - 1) }
    func setIndex(_ i: Int) { index = min(count - 1, max(0, i)) }

    func select(_ set: MysterySet) {
        mystery = set
        steps = RosaryBuilder.steps(for: set)
        index = 0
    }
}
