// MARK: - Facts & Decision integration extension
import Foundation
import RealityKit
import ARKit
import QuartzCore

extension ARManager {
    /// Connects HeadGestureController callbacks to handle smile/frown automatically.
    func setupHeadGestureListener() {
        headGestureController.onGesture = { [weak self] gesture in
            guard let self = self, self.showFactSheet, let spot = self.currentFactSpot else { return }
            let decision: HeadDecision = (gesture == .smile) ? .accepted : .rejected
            self.handleFactDecision(decision, spot: spot)
        }
    }

    /// No-op per-frame method maintained for compatibility with ArenaController.
    func processFaceGestureIfNeeded() {}

    /// Handles the user's decision (accepted/rejected) from facts sheet or facial expressions.
    func handleFactDecision(_ decision: HeadDecision, spot: ARSpot) {
        DispatchQueue.main.async {
            self.showFactSheet = false
            self.isFactQuestionActive = false
        }
        guard decision != .none else { return }
        
        let emoji = (decision == .accepted) ? "😆" : "☹️"
        factController.spawnSymbol(systemName: "face.smiling.fill", at: spot)
        
        if decision == .accepted {
            triggerFeedback(
                message: "Yay! You became friends with the animal!",
                tone: .positive,
                haptic: .success,
                sound: .positiveChime
            )
        } else {
            triggerFeedback(
                message: "Friendship declined. Moving you out of the habitat!",
                tone: .negative,
                haptic: .warning,
                sound: .negativeBuzz
            )
            
            pushUserOutOfHabitat(for: spot)
        }
    }

    func pushUserOutOfHabitat(for spot: ARSpot) {
        guard let camera = cameraAnchor else { return }
        let cameraPos = camera.position(relativeTo: nil)
        let spotWorldPos = parentContainer.convert(position: spot.center, to: nil)
        
        let dir = SIMD3<Float>(spotWorldPos.x - cameraPos.x, 0, spotWorldPos.z - cameraPos.z)
        let len = length(dir)
        let pushDistance: Float = 1.5
        
        let pushDir: SIMD3<Float>
        if len > 0.01 {
            pushDir = dir / len
        } else {
            let right3D = camera.orientation(relativeTo: nil).act(SIMD3<Float>(1, 0, 0))
            pushDir = normalize(cross(SIMD3<Float>(0, 1, 0), SIMD3<Float>(right3D.x, 0, right3D.z)))
        }
        
        let pushOffset = pushDir * pushDistance
        let currentWorldPos = parentContainer.position(relativeTo: nil)
        let newWorldPos = currentWorldPos + pushOffset
        
        if let anchor = anchorRef {
            let newLocalPos = anchor.convert(position: newWorldPos, from: nil)
            var targetTransform = parentContainer.transform
            targetTransform.translation = newLocalPos
            
            // Smoothly slide the arena away
            parentContainer.move(to: targetTransform, relativeTo: parentContainer.parent, duration: 0.5, timingFunction: .easeInOut)
        } else {
            parentContainer.position = [newWorldPos.x, parentContainer.position.y, newWorldPos.z]
        }
    }
}
