//
//  AppState.swift
//  ARProject
//
//  Created by Ferdiansyah Annora on 13/07/26.
//

import Foundation
import Observation

@Observable
class AppState {
    var distanceToAnimal: Float = 999 // atur jarak button ke hewan
    var isAnimalRevealed: Bool = false // 
    var activeButton: ActiveButton? = nil // nentuin button yang aktif di kategori mana
    var growthValue: Float = 0.0 // buat slider
}

enum ActiveButton {
    case faseHidup, habitat, kasihMakan
}
