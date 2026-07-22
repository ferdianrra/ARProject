import RealityKit
import Foundation

class ResizeController {
    
    private func baseScale(for animalTypeName: String) -> Float {
        switch animalTypeName {
        case "butterfly": return 0.001
        case "Lioness": return 0.005
        case "MountainGoat": return 0.005
        case "Wolf": return 0.005
        default: return 0.005
        }
    }
    
    func setScale(_ newScale: Float, on animal: Entity?, animalTypeName: String) {
        guard let animal = animal else { return }
        let finalScale = newScale * baseScale(for: animalTypeName)
        animal.scale = SIMD3<Float>(repeating: finalScale)
    }
    
    
    func enterResizeMode(manager: ARManager) {
        guard let spot = manager.spots.first(where: { $0.isNear }),
              let animal = spot.animalModel else { return }
        
        manager.wanderController.stopWandering(at: spot, yHeight: manager.heightOffset(for: spot))
        
        let eyeLevelY: Float
        if let cam = manager.cameraAnchor {
            let camY = cam.position(relativeTo: manager.parentContainer).y
            eyeLevelY = max(0.65, camY - 0.15)
        } else {
            eyeLevelY = 0.75
        }
        
        var raised = animal.transform
        raised.translation = SIMD3<Float>(spot.center.x, eyeLevelY, spot.center.z)
        animal.move(to: raised, relativeTo: animal.parent, duration: 0.3, timingFunction: .easeInOut)
        
            if spot.animalTypeName == "butterfly", let cam = manager.cameraAnchor {
            var camPosInAnchorSpace = cam.position(relativeTo: manager.parentContainer)
            camPosInAnchorSpace.y = 0
            animal.look(at: camPosInAnchorSpace, from: raised.translation, relativeTo: manager.parentContainer)
        }
    }

    func exitResizeMode(manager: ARManager) {
        guard let spot = manager.spots.first(where: { $0.isNear }),
              let animal = spot.animalModel else { return }
        
        var grounded = animal.transform
        grounded.translation = SIMD3<Float>(spot.center.x, spot.groundOffset, spot.center.z)
        grounded.scale = spot.baseScale
        animal.move(to: grounded, relativeTo: animal.parent, duration: 0.3, timingFunction: .easeInOut)

        manager.wanderController.startWandering(animal, at: spot, anchor: manager.parentContainer, yHeight: manager.heightOffset(for: spot))
    }
}
