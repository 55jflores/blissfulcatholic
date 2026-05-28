//
//  RosaryModels.swift
//  Blissful Catholic
//
//  The Rosary as an explicit, complete, ordered list of steps (one tap each).
//  This is built correctly rather than from the prototype's approximate
//  53-bead formula — every prayer is present and in order.
//

import Foundation

struct RosaryPrayer: Equatable {
    let name: String
    let text: String
}

enum RosaryPrayers {
    static let signOfCross = RosaryPrayer(
        name: "Sign of the Cross",
        text: "In the name of the Father, and of the Son, and of the Holy Spirit. Amen.")
    static let creed = RosaryPrayer(
        name: "Apostles' Creed",
        text: "I believe in God, the Father almighty, Creator of heaven and earth…")
    static let ourFather = RosaryPrayer(
        name: "Our Father",
        text: "Our Father, who art in heaven, hallowed be thy name; thy kingdom come; thy will be done on earth as it is in heaven…")
    static let hailMary = RosaryPrayer(
        name: "Hail Mary",
        text: "Hail Mary, full of grace, the Lord is with thee. Blessed art thou among women, and blessed is the fruit of thy womb, Jesus…")
    static let gloryBe = RosaryPrayer(
        name: "Glory Be",
        text: "Glory be to the Father, and to the Son, and to the Holy Spirit. As it was in the beginning, is now, and ever shall be, world without end. Amen.")
    static let hailHolyQueen = RosaryPrayer(
        name: "Hail, Holy Queen",
        text: "Hail, Holy Queen, Mother of Mercy, our life, our sweetness, and our hope. To thee do we cry, poor banished children of Eve…")
}

/// One discrete step in the Rosary.
struct RosaryStep: Equatable {
    let prayer: RosaryPrayer
    /// 0 = opening, 1...5 = the decades, 6 = closing.
    let phase: Int
    let context: String
    /// Large structural bead (crucifix / Our Father / closing) vs a small Hail Mary bead.
    let isLargeBead: Bool
    /// True for the Glory Be that closes a decade — used for the decade haptic.
    let closesDecade: Bool

    init(_ prayer: RosaryPrayer, phase: Int, context: String,
         isLargeBead: Bool = false, closesDecade: Bool = false) {
        self.prayer = prayer
        self.phase = phase
        self.context = context
        self.isLargeBead = isLargeBead
        self.closesDecade = closesDecade
    }
}

enum RosaryBuilder {
    static func steps(for set: MysterySet) -> [RosaryStep] {
        var steps: [RosaryStep] = []

        // Opening
        steps.append(.init(RosaryPrayers.signOfCross, phase: 0, context: "Opening", isLargeBead: true))
        steps.append(.init(RosaryPrayers.creed, phase: 0, context: "We profess our faith", isLargeBead: true))
        steps.append(.init(RosaryPrayers.ourFather, phase: 0, context: "For faith", isLargeBead: true))
        for n in 1...3 {
            steps.append(.init(RosaryPrayers.hailMary, phase: 0,
                               context: "For faith, hope, and love · \(n)/3"))
        }
        steps.append(.init(RosaryPrayers.gloryBe, phase: 0, context: "Glory to the Father"))

        // Five decades
        for (index, title) in set.mysteries.enumerated() {
            let decade = index + 1
            steps.append(.init(RosaryPrayers.ourFather, phase: decade,
                               context: "\(ordinal(decade)) mystery — \(title)", isLargeBead: true))
            for n in 1...10 {
                steps.append(.init(RosaryPrayers.hailMary, phase: decade, context: "\(title) · \(n)/10"))
            }
            steps.append(.init(RosaryPrayers.gloryBe, phase: decade,
                               context: title, closesDecade: true))
        }

        // Closing
        steps.append(.init(RosaryPrayers.hailHolyQueen, phase: 6, context: "In conclusion", isLargeBead: true))
        steps.append(.init(RosaryPrayers.signOfCross, phase: 6, context: "Go in peace", isLargeBead: true))

        return steps
    }

    private static func ordinal(_ n: Int) -> String {
        ["First", "Second", "Third", "Fourth", "Fifth"][safe: n - 1] ?? "\(n)th"
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
