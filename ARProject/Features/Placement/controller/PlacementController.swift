import RealityKit
import Foundation
import SwiftUI
import ARKit

final class PlacementController {
    // MARK: - Private storage
    private weak var manager: ARManager?
    
    // MARK: - Init
    init(manager: ARManager) {
        self.manager = manager
    }
    
    // MARK: - Legacy placement (camera math projection)
    //
    // Kept intact for reference and backward compatibility.
    // NOT used in the active flow — see handleTap(at:) below.
    //
    // WHY THIS ISN'T BEST PRACTICE:
    // It computes placement by projecting the camera's forward vector onto
    // the known plane height — purely mathematical. It doesn't verify the
    // computed position actually lands on an ARKit-detected plane polygon.
    // Any downward camera angle (forward.y <= -0.5) + close enough distance
    // would succeed, even if the user is looking slightly past a meja.
    func handleTap() {
        guard let manager = manager,
              let camAnchor = manager.cameraAnchor,
              let anchor = manager.anchorRef,
              !manager.isPlaced else { return }
        
        let planeHeight = anchor.position(relativeTo: nil).y
        let camPos = camAnchor.position(relativeTo: nil)
        let orientation = camAnchor.orientation(relativeTo: nil)
        let forward = orientation.act(SIMD3<Float>(0, 0, -1))
        
        // ORIGINAL guard — camera must tilt slightly downward (≈6°).
        // guard forward.y < -0.1 else { return }

        // UPDATED guard — camera must face downward at least ≈30°.
        // This prevents placement when looking at walls or the sky.
        guard forward.y <= -0.5 else { return }
        
        let t = (planeHeight - camPos.y) / forward.y
        guard t > 0 else { return }
        
        let intersectionWorld = camPos + t * forward

        // ADDED: Reject taps whose intersection point is more than 2.5 m away.
        // This prevents placement in mid-air or far-away locations.
        let distanceFromCamera = length(intersectionWorld - camPos)
        guard distanceFromCamera <= 2.5 else { return }

        let localPos = anchor.convert(position: intersectionWorld, from: nil)
        manager.parentContainer.position = [localPos.x, 0, localPos.z]
        finalize(manager: manager)
    }

    // MARK: - Best-practice placement (raycast from actual tap point)
    //
    // This is the ACTIVE method called from ContentView via DragGesture.
    //
    // HOW IT WORKS:
    // arView.raycast(from: point, allowing: .existingPlaneGeometry, alignment: .horizontal)
    // fires a ray from the exact pixel the user tapped.
    // It only returns a result if that ray hits the REAL surface of a detected
    // horizontal plane — not a mathematical projection, not an infinite extension.
    //
    // WHY THIS IS BEST PRACTICE:
    // 1. Uses the exact finger location on screen, not camera orientation.
    // 2. Only succeeds on ARKit-tracked plane geometry (not mid-air, not walls).
    // 3. If the user taps on a meja or wall → results empty → tap silently ignored.
    // 4. The user is then free to tap again on a valid floor surface.
    func handleTap(at point: CGPoint) {
        guard let manager = manager,
              let anchor = manager.anchorRef,
              let arView = manager.arView,
              !manager.isPlaced else { return }

        // Raycast from the exact tap pixel — existingPlaneGeometry only (no infinite fallback).
        // This means the tap must land on a real ARKit-detected plane polygon.
        let results = arView.raycast(from: point, allowing: .existingPlaneGeometry, alignment: .horizontal)

        // If nothing is hit (mid-air, wall, ceiling, table not yet classified) → ignore tap.
        guard let first = results.first else { return }

        // Extract the world-space position where the ray hit the floor plane.
        let worldPos = SIMD3<Float>(
            first.worldTransform.columns.3.x,
            first.worldTransform.columns.3.y,
            first.worldTransform.columns.3.z
        )

        // Convert to anchor-local space and place container at that XZ position.
        let localPos = anchor.convert(position: worldPos, from: nil)
        manager.parentContainer.position = [localPos.x, 0, localPos.z]
        finalize(manager: manager)
    }

    // MARK: - Shared finalization (identical for both placement paths)
    private func finalize(manager: ARManager) {
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
                let animals = ["butterfly", "Lioness", "MountainGoat", "Wolf"]
                
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
                    manager.habitatController.setFlowerHabitat(at: spot, count: 6, scale: 0.0012, scatteringRadius: 0.2, template: manager.flowerHabitatTemplate, anchor: manager.parentContainer)
                }
            } catch {
                print("error load flower_habitat.usdz: \(error)")
            }
        }
    }
}
