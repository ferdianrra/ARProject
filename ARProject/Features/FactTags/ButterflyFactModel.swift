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
    let emoji: String   // isi sekarang nama SF Symbol
}

enum HeadDecision {
    case none
    case accepted
    case rejected
}

struct AnimalFactData {
    // Butterfly tetap sama seperti sebelumnya
    static let butterfly: [ButterflyFact] = [
        ButterflyFact(
            title: "Prismatic Wings",
            text: "Butterfly wings are actually clear! Thousands of tiny scales reflect light to create their brilliant, shimmering colors.",
            emoji: "sparkles"
        ),
        ButterflyFact(
            title: "Tasting with Feet",
            text: "Butterflies taste food with their feet! Landing on a plant helps them test if it's safe to eat or lay eggs.",
            emoji: "pawprint.fill"
        ),
        ButterflyFact(
            title: "Solar Fliers",
            text: "Butterflies need warmth to fly! They bask in morning sunlight to warm up their wing muscles before taking off.",
            emoji: "sun.max.fill"
        ),
        ButterflyFact(
            title: "Global Pollinators",
            text: "With over 20,000 species worldwide, butterflies help plants grow and flowers bloom everywhere.",
            emoji: "leaf.fill"
        )
    ]
    
    // 🔧 Mountain Goat — sourced from Britannica, Animalia.bio, Alaska Dept. of Fish and Game
    static let mountainGoat: [ButterflyFact] = [
        ButterflyFact(
            title: "Not Actually a Goat",
            text: "Despite the name, mountain goats aren't true goats at all. They're more closely related to antelope, part of the same family as cattle and gazelles.",
            emoji: "mountain.2.fill"
        ),
        ButterflyFact(
            title: "Master Climbers",
            text: "Their feet have rough inner pads for grip and cloven hooves that spread apart for balance, letting them climb slopes steeper than 60 degrees.",
            emoji: "figure.climbing"
        ),
        ButterflyFact(
            title: "Woolly Double Coat",
            text: "A dense woolly undercoat covered by longer hollow outer hairs keeps them warm through brutal alpine winters, then sheds away completely by summer.",
            emoji: "snowflake"
        ),
        ButterflyFact(
            title: "Highest Mammal Around",
            text: "Living above 13,000 feet in places, mountain goats are the largest mammal found at such extreme high-altitude elevations.",
            emoji: "arrow.up.to.line"
        )
    ]
    
    // 🔧 Lioness — sourced from Lion Landscapes, Wildlife Conservation Network, A-Z Animals
    static let lioness: [ButterflyFact] = [
        ButterflyFact(
            title: "The Pride's Hunters",
            text: "Lionesses carry out the vast majority of a pride's hunts, while male lions spend most of their energy defending the pride's territory instead.",
            emoji: "bolt.fill"
        ),
        ButterflyFact(
            title: "Coordinated Ambush",
            text: "When hunting together, lionesses spread into a semicircle, with the strongest positioned at the center to make the kill while others block the prey's escape routes.",
            emoji: "figure.stand.line.dotted.figure.stand"
        ),
        ButterflyFact(
            title: "A Family of Sisters",
            text: "The lionesses in a pride are almost always related, mothers, daughters, and sisters, staying together for life and raising cubs as one family.",
            emoji: "person.3.fill"
        ),
        ButterflyFact(
            title: "Shared Motherhood",
            text: "Lionesses in a pride often give birth around the same time, and cubs may nurse from any lactating female, not just their own mother.",
            emoji: "heart.fill"
        )
    ]
    
    // 🔧 Wolf — sourced from Wikipedia (Wolf communication), Living with Wolves, seacrestwolfpreserve.org
    static let wolf: [ButterflyFact] = [
        ButterflyFact(
            title: "Howls That Travel Miles",
            text: "A wolf's howl can carry for miles across open terrain, helping separated pack members find each other and warning rival packs to stay away.",
            emoji: "waveform"
        ),
        ButterflyFact(
            title: "Every Howl Is Unique",
            text: "Each wolf has a distinct howl, almost like a voice fingerprint, letting pack members recognize exactly who is calling from far away.",
            emoji: "person.wave.2.fill"
        ),
        ButterflyFact(
            title: "Tails Tell a Story",
            text: "Wolves communicate rank and mood through body language too. A tail held high signals confidence, while a tucked tail shows submission.",
            emoji: "figure.walk"
        ),
        ButterflyFact(
            title: "A True Family Pack",
            text: "Most wolf packs are simply a family: a breeding pair and their pups from recent years, working together and rarely fighting among themselves.",
            emoji: "person.2.fill"
        )
    ]
    
    static func facts(for animalTypeName: String) -> [ButterflyFact] {
        switch animalTypeName {
        case "MountainGoat": return mountainGoat
        case "Lioness": return lioness
        case "Wolf": return wolf
        case "butterfly": return butterfly
        default: return butterfly
        }
    }
}
