import RealityKit
import Foundation

class WanderController {
    
    func spawnButterfly(at spot: ARSpot, template: Entity, anchor: AnchorEntity) {
        let butterfly = template.clone(recursive: true)
        butterfly.scale = SIMD3<Float>(repeating: 0.001)
        let point = randomPointInCircle(radius: 1.3)
        butterfly.position = [spot.center.x + point.x, 0.35, spot.center.z + point.y]
        anchor.addChild(butterfly)
        playAllAnimationsRecursive(butterfly)
        spot.activeButterfly = butterfly
        startWandering(butterfly, at: spot, anchor: anchor)
    }
    
    func startWandering(_ butterfly: Entity, at spot: ARSpot, anchor: AnchorEntity) {
        playAllAnimationsRecursive(butterfly)
        moveToNewRandomPoint(butterfly, at: spot, anchor: anchor)

        let interval: TimeInterval = 4.0
        spot.wanderTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self, weak butterfly] _ in
            guard let self = self, let butterfly = butterfly else { return }
            self.moveToNewRandomPoint(butterfly, at: spot, anchor: anchor)
        }
    }
    
    private func moveToNewRandomPoint(_ butterfly: Entity, at spot: ARSpot, anchor: AnchorEntity) {
        let point = randomPointInCircle(radius: 1.3)
        let targetPosition = SIMD3<Float>(spot.center.x + point.x, 0.35, spot.center.z + point.y)

        let currentPosition = butterfly.position
        let direction = normalize(targetPosition - currentPosition)
        let targetRotation = simd_quatf(from: [0, 0, 1], to: direction)

        var targetTransform = butterfly.transform
        targetTransform.translation = targetPosition
        targetTransform.rotation = targetRotation

        butterfly.move(to: targetTransform, relativeTo: anchor, duration: 3.5, timingFunction: .easeInOut)
    }
    
    func stopWandering(at spot: ARSpot) {
        spot.wanderTimer?.invalidate()
        spot.wanderTimer = nil
        
        if let active = spot.activeButterfly {
            var targetTransform = Transform.identity
            targetTransform.translation = spot.center
            targetTransform.scale = active.scale
            
            active.move(to: targetTransform, relativeTo: active.parent, duration: 1.5, timingFunction: .easeInOut)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self, weak active] in
                guard let self = self, let active = active else { return }
                if !spot.isNear {
                    self.stopAllAnimationsRecursive(active)
                }
            }
        }
    }
    
    private func randomPointInCircle(radius: Float) -> SIMD2<Float> {
        let angle = Float.random(in: 0..<(2 * Float.pi))
        let r = radius * sqrt(Float.random(in: 0...1))
        let x = cos(angle) * r
        let z = sin(angle) * r
        return SIMD2<Float>(x, z)
    }
    
    func stopAllAnimationsRecursive(_ entity: Entity) {
        entity.stopAllAnimations()
        for child in entity.children {
            stopAllAnimationsRecursive(child)
        }
    }

    func playAllAnimationsRecursive(_ entity: Entity) {
        for animation in entity.availableAnimations {
            entity.playAnimation(animation.repeat())
        }
        for child in entity.children {
            playAllAnimationsRecursive(child)
        }
    }
}
