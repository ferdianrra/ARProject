import RealityKit
import Foundation
import UIKit

class LifeCycleController {
    
    func changePhase(to phase: Int, manager: ARManager) {
        guard let anchor = manager.cameraAnchor?.parent as? AnchorEntity ?? manager.animalEntity?.parent as? AnchorEntity else { return }
        
        var assetName = ""
        switch phase {
        case 1: assetName = "butterfly_egg.usdc"
        case 2: assetName = "butterfly_ulat.usdz"
        case 3: assetName = "kepompong.usdz"
        case 4: assetName = "butterfly_idle.usdz"
        default: assetName = "butterfly_egg.usdc"
        }
        
        if manager.currentAnimalName != assetName {
            spawnAnimal(name: assetName, on: anchor, manager: manager)
        }
    }
    
    func exitLifeCycle(manager: ARManager) {
        guard let anchor = manager.cameraAnchor?.parent as? AnchorEntity ?? manager.animalEntity?.parent as? AnchorEntity else { return }
        
        let assetName = "butterfly.usdz"
        if manager.currentAnimalName != assetName {
            // We need a slightly modified spawn for exiting back to wandering
            spawnAnimal(name: assetName, on: anchor, manager: manager, forceWander: true)
        }
    }
    
    private func spawnAnimal(name animalName: String, on pAnchor: AnchorEntity, manager: ARManager, forceWander: Bool = false) {
        guard let loadedAnimal = try? Entity.load(named: animalName) else { return }
        
        let targetScale: Float = animalName == "butterfly_idle.usdz" ? 0.001 : 0.003
        loadedAnimal.scale = [0, 0, 0]
        
        // Ensure the loaded animal has an InputTargetComponent to receive gestures
        if !loadedAnimal.components.has(InputTargetComponent.self) {
            loadedAnimal.components.set(InputTargetComponent())
        } else {
            // Re-assign to make sure it's active
            loadedAnimal.components.set(InputTargetComponent())
        }
        
        // Remove existing animal if any
        if let spot = manager.spots.first(where: { $0.isNear }) {
            manager.wanderController.stopWandering(at: spot)
            
            if let existing = spot.activeButterfly {
                existing.removeFromParent()
            }
            
            pAnchor.addChild(loadedAnimal)
            spot.activeButterfly = loadedAnimal
            
            // Snap the lifecycle model exactly to the center of the spot so it doesn't wander
            // (If forceWander is true, it will start wandering AFTER the bounce animation finishes)
            loadedAnimal.position = spot.center
            
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
        
        // Add 3D Text Label for the Phase
        let phaseName = getPhaseName(from: animalName)
        let textEntity = createPhaseText(text: phaseName)
        let inverseScale = 1.0 / targetScale
        textEntity.scale = SIMD3<Float>(repeating: inverseScale)
        // Position it 30cm above the animal
        textEntity.position = SIMD3<Float>(0, 0.30 * inverseScale, 0)
        // Make it face the camera initially
        if let cam = manager.cameraAnchor {
            textEntity.look(at: cam.position(relativeTo: loadedAnimal), from: textEntity.position, relativeTo: loadedAnimal)
            textEntity.transform.rotation *= simd_quatf(angle: .pi, axis: [0, 1, 0])
        }
        loadedAnimal.addChild(textEntity)
        
        // Use a timer for the bounce animation
        var animTimer: Float = 0.0
        let animDuration: Float = 0.8
        
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            animTimer += 0.02
            if animTimer >= animDuration {
                timer.invalidate()
                loadedAnimal.scale = SIMD3<Float>(repeating: targetScale)
                
                DispatchQueue.main.async {
                    manager.currentAnimalName = animalName
                }
                
                // If it's supposed to wander, start wandering AFTER the bounce completes
                // so we don't cancel RealityKit's internal .move() animation!
                if forceWander, let spot = manager.spots.first(where: { $0.isNear }) {
                    manager.wanderController.startWandering(loadedAnimal, at: spot, anchor: pAnchor)
                }
            } else {
                let progress = animTimer / animDuration
                let bounceScale = Float(sin(progress * .pi / 2)) * targetScale
                loadedAnimal.scale = [bounceScale, bounceScale, bounceScale]
            }
        }
    }
    
    private func getPhaseName(from assetName: String) -> String {
        switch assetName {
        case "butterfly_egg.usdc": return "Phase 1: Egg"
        case "butterfly_ulat.usdz": return "Phase 2: Caterpillar"
        case "kepompong.usdz": return "Phase 3: Chrysalis"
        case "butterfly_idle.usdz": return "Phase 4: Butterfly"
        default: return "Unknown Phase"
        }
    }
    
    private func createPhaseText(text: String) -> Entity {
        let textMesh = MeshResource.generateText(text, 
                                                 extrusionDepth: 0.002, 
                                                 font: .boldSystemFont(ofSize: 0.04), 
                                                 containerFrame: .zero, 
                                                 alignment: .center, 
                                                 lineBreakMode: .byWordWrapping)
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [material])
        
        // Center the text mathematically
        let bounds = textEntity.visualBounds(relativeTo: nil)
        let centerOffset = -(bounds.extents / 2)
        textEntity.position = SIMD3<Float>(centerOffset.x, 0, 0)
        
        let wrapper = Entity()
        wrapper.name = "phaseText"
        wrapper.addChild(textEntity)
        return wrapper
    }
}
