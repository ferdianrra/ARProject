import RealityKit
import Foundation

class WanderController {
    
    func spawnButterfly(at spot: ARSpot, template: Entity, anchor: Entity) {
        let butterfly = template.clone(recursive: true)
        butterfly.scale = SIMD3<Float>(repeating: 0.001)
        
        var chosenSpawnPoint: SIMD3<Float>? = nil
        let centerWorld = anchor.convert(position: spot.center, to: nil)
        
        for _ in 0..<5 {
            let point = randomPointInCircle(radius: 1.3)
            let candidateLocal = SIMD3<Float>(spot.center.x + point.x, 0.35, spot.center.z + point.y)
            let candidateWorld = anchor.convert(position: candidateLocal, to: nil)
            
            if let hits = butterfly.scene?.raycast(from: centerWorld, to: candidateWorld), !hits.isEmpty {
                continue
            } else {
                chosenSpawnPoint = candidateLocal
                break
            }
        }
        
        let spawnPositionLocal = chosenSpawnPoint ?? SIMD3<Float>(spot.center.x, 0.35, spot.center.z)
        butterfly.position = spawnPositionLocal
        anchor.addChild(butterfly)
        playAllAnimationsRecursive(butterfly)
        spot.activeButterfly = butterfly
        startWandering(butterfly, at: spot, anchor: anchor)
    }
    
    func startWandering(_ butterfly: Entity, at spot: ARSpot, anchor: Entity) {
        playAllAnimationsRecursive(butterfly)
        moveToNewRandomPoint(butterfly, at: spot, anchor: anchor)

        let interval: TimeInterval = 4.0
        spot.wanderTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self, weak butterfly] _ in
            guard let self = self, let butterfly = butterfly else { return }
            self.moveToNewRandomPoint(butterfly, at: spot, anchor: anchor)
        }
    }
    
    private func moveToNewRandomPoint(_ butterfly: Entity, at spot: ARSpot, anchor: Entity) {
        let currentPositionWorld = butterfly.position(relativeTo: nil)
        var chosenTargetLocal: SIMD3<Float>? = nil
        
        for _ in 0..<5 {
            let point = randomPointInCircle(radius: 1.3)
            let candidateLocal = SIMD3<Float>(spot.center.x + point.x, 0.35, spot.center.z + point.y)
            let candidateWorld = anchor.convert(position: candidateLocal, to: nil)
            
            if let hits = butterfly.scene?.raycast(from: currentPositionWorld, to: candidateWorld), !hits.isEmpty {
                continue
            } else {
                chosenTargetLocal = candidateLocal
                break
            }
        }
        
        let targetPositionLocal = chosenTargetLocal ?? SIMD3<Float>(spot.center.x, 0.35, spot.center.z)
        let currentPositionLocal = butterfly.position
        let direction = normalize(targetPositionLocal - currentPositionLocal)
        let targetRotation = simd_quatf(from: [0, 0, 1], to: direction)

        var targetTransform = butterfly.transform
        targetTransform.translation = targetPositionLocal
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
