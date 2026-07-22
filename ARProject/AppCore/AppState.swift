import Foundation
import Observation

@Observable
class AppState {
    var distanceToAnimal: Float = 999
    var isAnimalRevealed: Bool = false
    var activeButton: ActiveButton? = nil
    var growthValue: Float = 0.0
}

enum ActiveButton {
    case faseHidup, habitat, kasihMakan
}



