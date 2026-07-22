// MARK: - Feeding integration extension
import Foundation
import RealityKit
import ARKit
import Vision
import SwiftUI

enum FeedingOverlayState {
    case reaching
    case feeding
}

extension ARManager {
    /// Wrapper that forwards to the feeding controller.
    func startFeedingMode() {
        feedingOverlayState = .reaching
        feedingController.spawnFood(manager: self)
    }

    /// Wrapper that forwards to the feeding controller.
    func stopFeedingMode() {
        isFeedingActive = false
        feedingController.stopFeeding()
    }
    
    func updateButterflyFlight(for targetEntity: Entity, speed: Float) {
        guard let butterfly = animalEntity else { return }
        
        let targetPos = targetEntity.position(relativeTo: nil)
        var currentPos = butterfly.position(relativeTo: nil)
        
        // Move towards target smoothly
        currentPos = simd_mix(currentPos, targetPos, SIMD3<Float>(repeating: speed))
        butterfly.setPosition(currentPos, relativeTo: nil)
        
        // Face the target smoothly to avoid NaN crash
        let lookTarget = SIMD3<Float>(targetPos.x, currentPos.y, targetPos.z)
        butterfly.look(at: lookTarget, from: currentPos, relativeTo: nil)
    }
}
