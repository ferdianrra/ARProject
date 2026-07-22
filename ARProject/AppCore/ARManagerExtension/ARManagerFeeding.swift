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
        
        if let spot = spots.first(where: { $0.isNear }) {
            wanderController.pauseWandering(at: spot)
            
            // Forcibly stop the movePlaybackController if it's still running
            if let butterfly = spot.animalModel {
                let currentTransform = butterfly.transform
                butterfly.move(to: currentTransform, relativeTo: butterfly.parent, duration: 0.01)
            }
        }
        
        // Also call the animal to the user so it's perfectly positioned for feeding!
        feedingController.callAnimal(manager: self)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showFeedingGuide = true
        }
    }

    /// Wrapper that forwards to the feeding controller.
    func stopFeedingMode() {
        isFeedingActive = false
        feedingController.stopFeeding()
        
        // Only resume wandering if we are actually still in the spot!
        // (If we walked out, ArenaController already handles stopping it)
        if let spot = spots.first(where: { $0.isNear }), let butterfly = spot.animalModel, spot.isNear {
            wanderController.resumeWandering(butterfly: butterfly, at: spot, anchor: parentContainer, yHeight: heightOffset(for: spot))
        }
    }
    
    func updateButterflyFlight(for targetEntity: Entity, speed: Float) {
        guard let butterfly = animalEntity, let camera = cameraAnchor else { return }
        
        let cameraPos = camera.position(relativeTo: nil)
        let foodPos = targetEntity.position(relativeTo: nil)
        
        let diff = foodPos - cameraPos
        let dist = length(diff)
        let direction = dist > 0.001 ? diff / dist : SIMD3<Float>(0, 0, -1)
        
        // Target is 5cm behind the food (further from camera)
        let targetPos = foodPos + (direction * 0.05)
        
        let currentPos = butterfly.position(relativeTo: nil)
        
        // Manual smooth interpolation (exactly like the recognition repo)
        let newPos = currentPos + (targetPos - currentPos) * speed
        butterfly.setPosition(newPos, relativeTo: nil)
        
        // Facing direction (flattened to completely prevent RealityKit look(at:) NaN crashes!)
        let lookDiff = SIMD3<Float>(foodPos.x - newPos.x, 0, foodPos.z - newPos.z)
        let lookLength = length(lookDiff)
        if lookLength > 0.001 {
            let facingDirection = lookDiff / lookLength
            // Safe rotation using atan2 to completely avoid the 180-degree NaN bug
            let angle = atan2(facingDirection.x, facingDirection.z)
            let targetRotation = simd_quatf(angle: angle, axis: SIMD3<Float>(0, 1, 0))
            
            // Assign directly! The position is already smoothly interpolated, so the rotation will naturally follow.
            // (simd_slerp can sometimes crash if quaternions are perfectly opposite).
            butterfly.transform.rotation = targetRotation
        }
    }
}
