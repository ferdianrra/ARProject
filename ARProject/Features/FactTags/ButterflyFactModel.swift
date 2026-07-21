//
//  ButterflyFactModel.swift
//  ARProject
//
//  Created by Ferdiansyah Annora on 21/07/26.
//

import Foundation

struct ButterflyFact: Identifiable {
    let id = UUID()
    let title: String
    let text: String
    let emoji: String
}

enum HeadDecision {
    case none
    case accepted
    case rejected
}

struct ButterflyFactData {
    static let facts: [ButterflyFact] = [
        ButterflyFact(
            title: "Prismatic Wings",
            text: "Butterfly wings are actually clear! Thousands of tiny scales reflect light to create their brilliant, shimmering colors.",
            emoji: "🪽"
        ),
        ButterflyFact(
            title: "Tasting with Feet",
            text: "Butterflies taste food with their feet! Landing on a plant helps them test if it's safe to eat or lay eggs.",
            emoji: "🐾"
        ),
        ButterflyFact(
            title: "Solar Fliers",
            text: "Butterflies need warmth to fly! They bask in morning sunlight to warm up their wing muscles before taking off.",
            emoji: "☀️"
        ),
        ButterflyFact(
            title: "Global Pollinators",
            text: "With over 20,000 species worldwide, butterflies help plants grow and flowers bloom everywhere.",
            emoji: "🌸"
        )
    ]
}
