//
//  SampleData.swift
//  Blissful Catholic
//
//  PHASE 1 placeholder content. Everything here is illustrative and hardcoded
//  so the skeleton is tappable and feels alive. Replaced by bundled JSON +
//  API.Bible + the Claude backend in Phase 4.
//

import Foundation

enum SampleData {

    static let philipNeri = Saint(
        name: "Saint Philip Neri",
        rank: "Memorial",
        years: "1515 – 1595",
        patronage: "Joy, humor, and the city of Rome",
        biography: """
        Known as the "Apostle of Rome" and the "Saint of Joy," Philip Neri drew \
        souls to God through warmth, laughter, and friendship rather than severity. \
        He founded the Oratory, gathering people for prayer, scripture, and song. \
        Famous for his playfulness, he insisted that holiness and gladness belong \
        together — "A heart filled with joy is more easily made perfect than one \
        that is sad."
        """,
        reflection: """
        Philip shows us that the path to God need not be grim. Where in your day \
        could you let a little holy joy break through?
        """
    )

    static let readings: [ScriptureReading] = [
        ScriptureReading(
            label: "First reading",
            citation: "Acts 18:23–28",
            excerpt: """
            He began to speak boldly in the synagogue; but when Priscilla and \
            Aquila heard him, they took him aside and explained to him the Way of \
            God more accurately.
            """
        ),
        ScriptureReading(
            label: "Responsorial psalm",
            citation: "Psalm 47:2–3, 8–9, 10",
            excerpt: "God is king of all the earth. Sing praise to God, sing praise."
        ),
        ScriptureReading(
            label: "Gospel",
            citation: "John 16:23b–28",
            excerpt: """
            Amen, amen, I say to you, whatever you ask the Father in my name he \
            will give you. Ask and you will receive, so that your joy may be complete.
            """
        )
    ]

    static let prompt = DailyPrompt(
        text: "Sit for a moment with one line of today's Gospel — \"so that your joy may be complete.\" What would complete joy look like in your life today?",
        feature: .lectio
    )

    /// The full context for the Daily home screen.
    static func todayContext() -> DailyContext {
        DailyContext(
            date: .now,
            season: LiturgicalCalendar.currentSeason(),
            feastTitle: "Saturday of the Seventh Week of Easter",
            saint: philipNeri,
            readings: readings,
            prompt: prompt
        )
    }

    /// A placeholder prayer streak for the skeleton.
    static let sampleStreak = 7
}
