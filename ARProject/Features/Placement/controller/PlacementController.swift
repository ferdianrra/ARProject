import RealityKit
import Foundation
import SwiftUI

final class PlacementController {
    // MARK: - Private storage
    private weak var manager: ARManager?
    
    // MARK: - Init
    init(manager: ARManager) {
        self.manager = manager
    }
    
    // MARK: - Public API
    func handleTap() {
        guard let manager = manager,
              let camAnchor = manager.cameraAnchor,
              let anchor = manager.anchorRef,
              !manager.isPlaced else { return }
        
        let planeHeight = anchor.position(relativeTo: nil).y
        let camPos = camAnchor.position(relativeTo: nil)
        let orientation = camAnchor.orientation(relativeTo: nil)
        let forward = orientation.act(SIMD3<Float>(0, 0, -1))
        
        guard forward.y < -0.1 else { return }
        
        let t = (planeHeight - camPos.y) / forward.y
        guard t > 0 else { return }
        
        let intersectionWorld = camPos + t * forward
        let localPos = anchor.convert(position: intersectionWorld, from: nil)
        
        manager.parentContainer.position = [localPos.x, 0, localPos.z]
        
        DispatchQueue.main.async {
            manager.isPlaced = true
        }
        
        manager.habitatController.setupHabitats(spots: manager.spots, planeAnchor: manager.parentContainer)
        
        manager.auraTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak manager] _ in
            manager?.habitatController.updateAura()
        }
        
        Task { [weak manager] in
            guard let manager = manager else { return }
            do {
                let animals = ["MountainGoat", "Wolf", "butterfly", "Lioness"]
                
                for (index, spot) in manager.spots.enumerated() {
                    let animalName = animals[index % animals.count]
                    
                    do {
                        let template = try await ModelEntity(named: animalName, in: nil)
                        
                        let scale: Float
                        
                        switch animalName {
                        case "butterfly":
                            scale = 0.001
                        case "Lioness":
                            scale = 0.005
                        case "MountainGoat":
                            scale = 0.005     
                        case "Wolf":
                            scale = 0.005
                        default:
                            scale = 0.005
                        }
                        
                        template.scale = SIMD3<Float>(repeating: scale)
                        

                        let bounds = template.visualBounds(relativeTo: template)
                        // If pivot is centered, this pulls the model's bottom edge down to y=0
//                        let groundOffset = -(bounds.min.y * scale)
                        
                        let preciseGroundOffset: Float
                        switch animalName {
                        case "butterfly": preciseGroundOffset = 1.0 // Ketinggian terbang
                        case "Lioness": preciseGroundOffset = 0.01
                        case "Wolf": preciseGroundOffset = 0.0
                        case "MountainGoat": preciseGroundOffset = 0.01
                        default: preciseGroundOffset = 0.0
                        }
                        
                        spot.groundOffset = preciseGroundOffset

                        print("\(animalName) scaled size: \(bounds.extents), groundOffset: \(preciseGroundOffset)")
                        
                        let scaledBounds = template.visualBounds(relativeTo: nil)
                        print("\(animalName) scaled size (meters): \(scaledBounds.extents)")
                        
                        switch animalName {
                        case "butterfly": spot.audioName = "butterflyWing.wav"
                        case "Lioness": spot.audioName = "lion.wav"
                        case "MountainGoat": spot.audioName = "sheep.flac"
                        case "Wolf": spot.audioName = "wolf.wav"
                        default: spot.audioName = ""
                        }
                        
                        spot.animalTypeName = animalName
                        spot.animalTemplate = template.clone(recursive: true)
                        
                        if animalName == "butterfly" {
                            manager.butterflyTemplate = spot.animalTemplate
                        }
                        
                        let reflectiveAnimal = template.clone(recursive: true)
                        manager.habitatController.setReflective(reflectiveAnimal)
                        manager.wanderController.stopAllAnimationsRecursive(reflectiveAnimal)
                        
                        let isFlyer = animalName == "butterfly"
                        let reflectiveY = isFlyer ? 0.5 : spot.groundOffset
                        
//                        reflectiveAnimal.position = spot.center
                        reflectiveAnimal.position = SIMD3<Float>(spot.center.x, reflectiveY, spot.center.z)
                        manager.parentContainer.addChild(reflectiveAnimal)
                        spot.reflectiveAnimal = reflectiveAnimal
                        
                        
                        if !spot.audioName.isEmpty {
                            let audioEntity = manager.createSpatialAudio(audioName: spot.audioName)
                            reflectiveAnimal.addChild(audioEntity)
                            spot.spatialAudioEntity = audioEntity
                        }
                        
                    } catch {
                        print("error loading \(animalName): \(error)")
                        continue   // move on to the next animal instead of killing the whole loop
                    }
                }
            } catch {
                print("error load butterfly.usdz: \(error)")
            }
            
            do {
                let flowerTemplate = try await Entity(named: "flower_habitat", in: nil)
                manager.flowerHabitatTemplate = flowerTemplate
                
                for spot in manager.spots {
                    if spot.animalTypeName == "butterfly" {
                        manager.habitatController.setFlowerHabitat(at: spot, count: 6, scale: 0.0006, scatteringRadius: 0.2, template: manager.flowerHabitatTemplate, anchor: manager.parentContainer)
                    }
                }
            } catch {
                print("error load flower_habitat.usdz: \(error)")
            }
        }
    }
}
