import RealityKit
import Foundation

class ARSpot {
    let id: Int
    let center: SIMD3<Float>
    var hasVisited: Bool = false
    var isNear: Bool = false
    
    var blackButterfly: Entity?
    var activeButterfly: Entity?
    var wanderTimer: Timer?
    var scatteredFlowers: [Entity] = []
    
    var reflectiveAnimal:ModelEntity?
    var animalModel: Entity?
    var animalModelName: Entity?
    
    var circleEntity: ModelEntity?
    var wingAudioController: AudioPlaybackController?
    var audioName: String

    init(id: Int, center: SIMD3<Float>, animalModel: ModelEntity? = nil, audioName: String = "") {
        self.id = id
        self.center = center
        self.hasVisited = false
        self.animalModel = animalModel
        self.audioName = audioName
        
    }
}
