import RealityKit
import Foundation

class ResizeController {
    func setScale(_ newScale: Float, on animal: Entity?) {
        guard let animal = animal else { return }
        // Base target scale is 0.001, so we multiply the newScale by 0.001
        let finalScale = newScale * 0.001
        animal.scale = SIMD3<Float>(repeating: finalScale)
    }
    
    func enterResizeMode(manager: ARManager) {
        guard let anchor = manager.cameraAnchor?.parent as? AnchorEntity ?? manager.animalEntity?.parent as? AnchorEntity else { return }
        
        let assetName = "butterfly_idle.usdz"
        if manager.currentAnimalName != assetName {
            spawnAnimal(name: assetName, on: anchor, manager: manager, forceWander: false)
        }
    }
    
    func exitResizeMode(manager: ARManager) {
        guard let anchor = manager.cameraAnchor?.parent as? AnchorEntity ?? manager.animalEntity?.parent as? AnchorEntity else { return }
        
        let assetName = "butterfly.usdz"
        if manager.currentAnimalName != assetName {
            spawnAnimal(name: assetName, on: anchor, manager: manager, forceWander: true)
        }
    }
    
    // Shared spawn helper similar to LifecycleController
    private func spawnAnimal(name animalName: String, on pAnchor: AnchorEntity, manager: ARManager, forceWander: Bool = false) {
        guard let loadedAnimal = try? Entity.load(named: animalName) else { return }
        
        // When entering resize mode, we preserve the current UI scale
        // For now, let's just initialize to base scale, the slider will immediately override it.
        let targetScale: Float = animalName == "butterfly_idle.usdz" ? 0.001 : 0.001
        loadedAnimal.scale = SIMD3<Float>(repeating: targetScale)
        
        if !loadedAnimal.components.has(InputTargetComponent.self) {
            loadedAnimal.components.set(InputTargetComponent())
        } else {
            loadedAnimal.components.set(InputTargetComponent())
        }
        
        if let spot = manager.spots.first(where: { $0.isNear }) {
            manager.wanderController.stopWandering(at: spot)
            
            if let existing = spot.activeButterfly {
                existing.removeFromParent()
            }
            
            pAnchor.addChild(loadedAnimal)
            spot.activeButterfly = loadedAnimal
            
            loadedAnimal.position = spot.center
            
            if forceWander {
                manager.wanderController.startWandering(loadedAnimal, at: spot, anchor: pAnchor)
            }
        } else {
            pAnchor.addChild(loadedAnimal)
        }
        
        if let animation = loadedAnimal.availableAnimations.first {
            loadedAnimal.playAnimation(animation.repeat())
        }
        
        if let cam = manager.cameraAnchor {
            var camPosInAnchorSpace = cam.position(relativeTo: pAnchor)
            camPosInAnchorSpace.y = 0
            loadedAnimal.look(at: camPosInAnchorSpace, from: [0, 0, 0], relativeTo: pAnchor)
        }
        manager.baseRotation = loadedAnimal.orientation
        manager.currentAnimalName = animalName
    }
}
