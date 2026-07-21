import RealityKit
import Foundation
import UIKit

class LifeCycleController {
    
    func changePhase(to phase: Int, manager: ARManager) {
        let anchor = manager.parentContainer
        
        var assetName = ""
        switch phase {
        case 1: assetName = "butterfly_egg.usdz"
        case 2: assetName = "Caterpillar_and_leaf.usdz"
        case 3: assetName = "Pupa_of_Graphium_agamemnon.usdz"
        case 4: assetName = "butterfly_idle.usdz"
        default: assetName = "butterfly_idle.usdz"
        }
        
        for spot in manager.spots {
            manager.wanderController.stopWandering(at: spot)
        }
        
        if manager.currentAnimalName != assetName {
            spawnAnimal(name: assetName, phase: phase, on: anchor, manager: manager)
        }
    }
    
    func exitLifeCycle(manager: ARManager) {
        let anchor = manager.parentContainer
        
        let assetName = "butterfly.usdz"
        if manager.currentAnimalName != assetName {
            if let spot = manager.spots.first(where: { $0.activeButterfly != nil }) {
                if let existing = spot.activeButterfly {
                    existing.removeFromParent()
                }
                
                if let template = manager.coloredButterflyTemplate {
                    manager.wanderController.spawnButterfly(at: spot, template: template, anchor: anchor)
                } else {
                    spawnAnimal(name: assetName, on: anchor, manager: manager, forceWander: true)
                }
                
                if let wingAudio = manager.butterflyWingAudio {
                    spot.wingAudioController = spot.activeButterfly?.playAudio(wingAudio)
                }
            } else {
                spawnAnimal(name: assetName, on: anchor, manager: manager, forceWander: true)
            }
            
            manager.currentAnimalName = assetName
        }
    }
    
    private func spawnAnimal(name animalName: String, phase: Int = 4, on pAnchor: Entity, manager: ARManager, forceWander: Bool = false) {
        guard let loadedAnimal = try? Entity.load(named: animalName) else { return }
        manager.currentAnimalName = animalName
        
        let targetScale: Float
        switch animalName {
        case "butterfly_egg.usdz":
            targetScale = 0.3
        case "Caterpillar_and_leaf.usdz":
            targetScale = 0.0003
        case "butterfly_idle.usdz", "butterfly.usdz":
            targetScale = 0.001
        default:
            targetScale = 0.003
        }
        
        loadedAnimal.scale = [0, 0, 0]
        if !loadedAnimal.components.has(InputTargetComponent.self) {
            loadedAnimal.components.set(InputTargetComponent())
        } else {
            loadedAnimal.components.set(InputTargetComponent())
        }
        
        let eyeLevelY: Float
        if let cam = manager.cameraAnchor {
            let camY = cam.position(relativeTo: pAnchor).y
            eyeLevelY = max(0.35, camY - 0.15)
        } else {
            eyeLevelY = 0.5
        }
        
        if let spot = manager.spots.first(where: { $0.activeButterfly != nil }) ?? manager.spots.first(where: { $0.isNear }) {
            manager.wanderController.stopWandering(at: spot)
            
            if let existing = spot.activeButterfly {
                existing.removeFromParent()
            }
            
            pAnchor.addChild(loadedAnimal)
            spot.activeButterfly = loadedAnimal
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
        
        if animalName == "butterfly_egg.usdz" {
            let rotX = simd_quatf(angle: .pi, axis: [1, 0, 0])
            let rotY = simd_quatf(angle: 30.0 * .pi / 180.0, axis: [0, 1, 0])
            loadedAnimal.orientation *= (rotX * rotY)
        } else if animalName == "Pupa_of_Graphium_agamemnon.usdz" {
            let rotZ = simd_quatf(angle: 90.0 * .pi / 180.0, axis: [0, 0, 1])
            let rotY = simd_quatf(angle: 90.0 * .pi / 180.0, axis: [0, 1, 0])
            loadedAnimal.orientation *= (rotZ * rotY)
        } else if animalName == "Caterpillar_and_leaf.usdz" {
            let rotZ = simd_quatf(angle: -45.0 * .pi / 180.0, axis: [0, 0, 1])
            loadedAnimal.orientation *= rotZ
        }
        
        manager.baseRotation = loadedAnimal.orientation
        
        var animTimer: Float = 0.0
        let animDuration: Float = 0.8
        
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            animTimer += 0.02
            if animTimer >= animDuration {
                timer.invalidate()
                loadedAnimal.scale = SIMD3<Float>(repeating: targetScale)
                
                if forceWander, let spot = manager.spots.first(where: { $0.activeButterfly != nil }) {
                    manager.wanderController.startWandering(loadedAnimal, at: spot, anchor: pAnchor)
                }
            } else {
                let progress = animTimer / animDuration
                let bounceScale = Float(sin(progress * .pi / 2)) * targetScale
                loadedAnimal.scale = [bounceScale, bounceScale, bounceScale]
            }
        }
    }
    
    private func getPhaseName(for phase: Int) -> String {
        switch phase {
        case 1: return "Phase 1: Egg"
        case 2: return "Phase 2: Caterpillar"
        case 3: return "Phase 3: Chrysalis"
        case 4: return "Phase 4: Butterfly"
        default: return ""
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
        let bounds = textEntity.visualBounds(relativeTo: nil)
        let centerOffset = -(bounds.extents / 2)
        textEntity.position = SIMD3<Float>(centerOffset.x, 0, 0)
        
        let wrapper = Entity()
        wrapper.name = "phaseText"
        wrapper.addChild(textEntity)
        return wrapper
    }
}
