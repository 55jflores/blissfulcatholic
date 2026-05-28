//
//  Enums.swift
//  Blissful Catholic
//
//  Shared domain enumerations used across features and (later) SwiftData models.
//

import Foundation

/// The user's state in life — shapes confession prep, formation, and tone.
enum StateInLife: String, CaseIterable, Codable, Identifiable {
    case single, married, religious, priest
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .single:    return "Single"
        case .married:   return "Married"
        case .religious: return "Religious"
        case .priest:    return "Priest"
        }
    }
}

/// How far along the user is in their faith — calibrates depth of AI responses.
enum FaithMaturity: String, CaseIterable, Codable, Identifiable {
    case beginner, intermediate, advanced
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .beginner:     return "New to the faith"
        case .intermediate: return "Growing"
        case .advanced:     return "Well-formed"
        }
    }
    var detail: String {
        switch self {
        case .beginner:     return "Just starting to explore Catholic life."
        case .intermediate: return "Praying regularly and learning more."
        case .advanced:     return "Deeply rooted and seeking to go further."
        }
    }
}

/// How the user came to the Catholic faith.
enum CatholicBackground: String, CaseIterable, Codable, Identifiable {
    case cradle, convert, returning
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .cradle:    return "Cradle Catholic"
        case .convert:   return "Convert"
        case .returning: return "Returning"
        }
    }
    var detail: String {
        switch self {
        case .cradle:    return "Raised in the faith."
        case .convert:   return "Came to the Church as an adult."
        case .returning: return "Coming home after time away."
        }
    }
}

/// Identifies which feature produced a session, journal entry, or insight.
enum AppFeature: String, CaseIterable, Codable, Identifiable {
    case lectio
    case rosary
    case examen
    case confession
    case catechism
    case saints
    case journal
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .lectio:     return "Lectio Divina"
        case .rosary:     return "Rosary"
        case .examen:     return "Examen"
        case .confession: return "Confession prep"
        case .catechism:  return "Catechism companion"
        case .saints:     return "Saints"
        case .journal:    return "Journal"
        }
    }
    var systemImage: String {
        switch self {
        case .lectio:     return "book.closed"
        case .rosary:     return "circle.grid.cross"
        case .examen:     return "moon.stars"
        case .confession: return "hands.and.sparkles"
        case .catechism:  return "bubble.left.and.text.bubble.right"
        case .saints:     return "person.crop.circle.badge.checkmark"
        case .journal:    return "pencil.and.outline"
        }
    }
}

/// The four sets of mysteries of the Holy Rosary.
enum MysterySet: String, CaseIterable, Codable, Identifiable {
    case joyful, sorrowful, glorious, luminous
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .joyful:    return "Joyful Mysteries"
        case .sorrowful: return "Sorrowful Mysteries"
        case .glorious:  return "Glorious Mysteries"
        case .luminous:  return "Luminous Mysteries"
        }
    }
    /// Traditional day of the week each set is prayed.
    var traditionalDays: String {
        switch self {
        case .joyful:    return "Monday & Saturday"
        case .sorrowful: return "Tuesday & Friday"
        case .glorious:  return "Wednesday & Sunday"
        case .luminous:  return "Thursday"
        }
    }
    /// The five mysteries within this set.
    var mysteries: [String] {
        switch self {
        case .joyful:
            return ["The Annunciation", "The Visitation", "The Nativity",
                    "The Presentation", "The Finding in the Temple"]
        case .sorrowful:
            return ["The Agony in the Garden", "The Scourging at the Pillar",
                    "The Crowning with Thorns", "The Carrying of the Cross",
                    "The Crucifixion"]
        case .glorious:
            return ["The Resurrection", "The Ascension", "The Descent of the Holy Spirit",
                    "The Assumption", "The Coronation of Mary"]
        case .luminous:
            return ["The Baptism in the Jordan", "The Wedding at Cana",
                    "The Proclamation of the Kingdom", "The Transfiguration",
                    "The Institution of the Eucharist"]
        }
    }

    /// The set traditionally prayed on a given weekday.
    static func recommended(for date: Date = .now) -> MysterySet {
        switch Calendar.current.component(.weekday, from: date) {
        case 1:  return .glorious   // Sunday
        case 2:  return .joyful     // Monday
        case 3:  return .sorrowful  // Tuesday
        case 4:  return .glorious   // Wednesday
        case 5:  return .luminous   // Thursday
        case 6:  return .sorrowful  // Friday
        default: return .joyful     // Saturday
        }
    }
}
