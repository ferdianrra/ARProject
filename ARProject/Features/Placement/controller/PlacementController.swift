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
                let template = try await Entity(named: "butterfly", in: nil)
                manager.coloredButterflyTemplate = template.clone(recursive: true)
                
                for spot in manager.spots {
                    guard !spot.isLocked else { continue }
                    let blackButterfly = template.clone(recursive: true)
                    manager.habitatController.setEntityColor(blackButterfly, color: .black)
                    manager.wanderController.stopAllAnimationsRecursive(blackButterfly)
                    blackButterfly.scale = SIMD3<Float>(repeating: 0.0008)
                    blackButterfly.position = SIMD3<Float>(spot.center.x, 0.40, spot.center.z)
                    manager.parentContainer.addChild(blackButterfly)
                    spot.blackButterfly = blackButterfly
                }
            } catch {
                print("error load butterfly.usdz: \(error)")
            }
            
            do {
                let flowerTemplate = try await Entity(named: "flower_habitat", in: nil)
                manager.flowerHabitatTemplate = flowerTemplate
                
                for spot in manager.spots {
                    guard !spot.isLocked else { continue }
                    manager.habitatController.setFlowerHabitat(at: spot, count: 6, scale: 0.0006, scatteringRadius: 0.2, template: manager.flowerHabitatTemplate, anchor: manager.parentContainer)
                }
            } catch {
                print("error load flower_habitat.usdz: \(error)")
            }
        }
    }
}
