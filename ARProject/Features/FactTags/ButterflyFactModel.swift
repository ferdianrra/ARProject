//
//  ButterflyFactModel.swift
//  ARProject
//
//  Created by Ferdiansyah Annora on 21/07/26.
//

import Foundation

struct ButterflyFact: Identifiable {
    let id = UUID()
    let text: String
}

enum HeadDecision {
    case none
    case accepted
    case rejected
}

struct ButterflyFactData {
    static let facts: [ButterflyFact] = [
        ButterflyFact(text: "Butterflies love to camouflage with their surroundings for self-protection."),
        ButterflyFact(text: "There are over 20,000 species of butterflies worldwide."),
        ButterflyFact(text: "Butterfly wing colors come from thousands of tiny microscopic chitin scales."),
        ButterflyFact(text: "Butterflies play a crucial role in plant pollination."),
        ButterflyFact(text: "Butterflies don't fear rain, but they cannot fly if their bodies get too cold!")
    ]
}
