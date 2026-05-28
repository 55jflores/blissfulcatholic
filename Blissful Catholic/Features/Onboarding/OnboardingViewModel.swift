//
//  OnboardingViewModel.swift
//  Blissful Catholic
//
//  Holds the user's onboarding selections. Phase 1 keeps the logic light:
//  no validation beyond "a choice is made." Phase 2 persists these onto the
//  SwiftData UserProfile.
//

import SwiftUI
import Observation

@Observable
final class OnboardingViewModel {
    enum Step: Int, CaseIterable {
        case welcome, name, background, stateInLife, faithMaturity, ready
    }

    var step: Step = .welcome

    var name: String = ""
    var background: CatholicBackground?
    var stateInLife: StateInLife?
    var faithMaturity: FaithMaturity?

    /// Whether the current step's requirement is satisfied.
    var canAdvance: Bool {
        switch step {
        case .welcome:       return true
        case .name:          return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case .background:    return background != nil
        case .stateInLife:   return stateInLife != nil
        case .faithMaturity: return faithMaturity != nil
        case .ready:         return true
        }
    }

    var isLastStep: Bool { step == .ready }
    var isFirstStep: Bool { step == .welcome }

    /// 0...1 progress for the indicator.
    var progress: Double {
        Double(step.rawValue) / Double(Step.allCases.count - 1)
    }

    func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    func back() {
        guard let prev = Step(rawValue: step.rawValue - 1) else { return }
        step = prev
    }
}
