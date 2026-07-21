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
        guard let spot = manager.spots.first(where: { $0.isNear }) else { return }
        let assetName = spot.animalTypeName
        let anchor = manager.parentContainer
        
        if manager.currentAnimalName != assetName {
            spawnAnimal(name: assetName, on: anchor, manager: manager, forceWander: false)
        }
    }

    func exitResizeMode(manager: ARManager) {
        guard let spot = manager.spots.first(where: { $0.isNear }) else { return }
        let assetName = spot.animalTypeName
        let anchor = manager.parentContainer
        
        if manager.currentAnimalName != assetName {
            if let existing = spot.animalModel {
                existing.removeFromParent()
            }
            if let template = spot.animalTemplate {
                let finalY = spot.center.y + spot.groundOffset + manager.flightExtra(for: spot.animalTypeName)
                manager.wanderController.spawnButterfly(at: spot, template: template, anchor: manager.parentContainer, yHeight: finalY)
            } else {
                spawnAnimal(name: assetName, on: anchor, manager: manager, forceWander: true)
            }
            if !spot.audioName.isEmpty, let animalModel = spot.animalModel {
                let audioEntity = manager.createSpatialAudio(audioName: spot.audioName)
                animalModel.addChild(audioEntity)
                spot.spatialAudioEntity = audioEntity
            }
            manager.currentAnimalName = assetName
        }
    }
    
    // Shared spawn helper similar to LifecycleController
    private func spawnAnimal(name animalName: String, on pAnchor: Entity, manager: ARManager, forceWander: Bool = false) {
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
        
        let eyeLevelY: Float
        if let cam = manager.cameraAnchor {
            let camY = cam.position(relativeTo: pAnchor).y
            eyeLevelY = max(0.65, camY - 0.15)
        } else {
            eyeLevelY = 0.75
        }
        
        if let spot = manager.spots.first(where: { $0.animalModel != nil }) ?? manager.spots.first(where: { $0.isNear }) {
            manager.wanderController.stopWandering(at: spot, yHeight: manager.heightOffset(for: spot))
            
            if let existing = spot.animalModel {
                existing.removeFromParent()
            }
            
            pAnchor.addChild(loadedAnimal)
            spot.animalModel = loadedAnimal
            loadedAnimal.position = SIMD3<Float>(spot.center.x, eyeLevelY, spot.center.z)
            
        } else {
            pAnchor.addChild(loadedAnimal)
            loadedAnimal.position = SIMD3<Float>(0, eyeLevelY, 0)
        }
        
        if let animation = loadedAnimal.availableAnimations.first {
            loadedAnimal.playAnimation(animation.repeat())
        }
        
        if let cam = manager.cameraAnchor {
            var camPosInAnchorSpace = cam.position(relativeTo: pAnchor)
            camPosInAnchorSpace.y = 0
            loadedAnimal.look(at: camPosInAnchorSpace, from: loadedAnimal.position, relativeTo: pAnchor)
        }
        manager.baseRotation = loadedAnimal.orientation
        manager.currentAnimalName = animalName
    }
}
