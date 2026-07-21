import RealityKit
import Foundation

class ARSpot {
    let id: Int
    let center: SIMD3<Float>
    let isLocked: Bool
    var hasVisited: Bool = false
    var isNear: Bool = false
    var isLockedNear: Bool = false
    
    var blackButterfly: Entity?
    var activeButterfly: Entity?
    var lockEntity: Entity?
    var wanderTimer: Timer?
    var scatteredFlowers: [Entity] = []
    
    var circleEntity: ModelEntity?
    var wingAudioController: AudioPlaybackController?

    init(id: Int, center: SIMD3<Float>, isLocked: Bool = false) {
        self.id = id
        self.center = center
        self.isLocked = isLocked
    }
}
