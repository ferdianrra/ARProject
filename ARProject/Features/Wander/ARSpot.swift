import RealityKit
import Foundation

class ARSpot {
    let id: Int
    let center: SIMD3<Float>
    var hasVisited: Bool = false
    var isNear: Bool = false
    var isLockedNear: Bool = false
    
    var animalTypeName: String = ""       
    var animalTemplate: ModelEntity?
    var spatialAudioEntity: Entity?
    var wanderTimer: Timer?
    var movePlaybackController: AnimationPlaybackController?
    var scatteredFlowers: [Entity] = []
    
    var reflectiveAnimal: ModelEntity?
    var animalModel: Entity?
    
    var circleEntity: ModelEntity?
    var wingAudioController: AudioPlaybackController?
    var audioName: String
    
    var groundOffset: Float = 0
    
    init(id: Int, center: SIMD3<Float>, animalModel: ModelEntity? = nil, audioName: String = "") {
        self.id = id
        self.center = center
        self.hasVisited = false
        self.animalModel = animalModel
        self.audioName = audioName
    }
}
