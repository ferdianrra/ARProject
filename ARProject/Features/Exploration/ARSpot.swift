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
    
    var circleEntity: ModelEntity?
    var wingAudioController: AudioPlaybackController?

    init(id: Int, center: SIMD3<Float>) {
        self.id = id
        self.center = center
    }
}
