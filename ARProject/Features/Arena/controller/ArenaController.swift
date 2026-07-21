import RealityKit
import Foundation
import SwiftUI

final class ArenaController {
    // MARK: - Private storage
    private weak var manager: ARManager?
    
    // MARK: - Init
    init(manager: ARManager) {
        self.manager = manager
    }
    
    // MARK: - Public API
    func update(cameraAnchor camAnchor: AnchorEntity, planeAnchor anchor: AnchorEntity) {
        guard let manager = manager else { return }
        
        if !manager.isPlaced {
            manager.distanceText = "Tap screen to place the area"
            DispatchQueue.main.async {
                if manager.isTooFar {
                    manager.isTooFar = false
                }
            }
            return
        }
        
        if manager.isFeedingActive {
            if manager.spots.first(where: { $0.isNear }) == nil {
                manager.stopFeedingMode()
                return
            }
            manager.updateFeedingIfNeeded()
        }

        let cameraPosition = camAnchor.position(relativeTo: nil)
        let cameraFlat = SIMD2<Float>(cameraPosition.x, cameraPosition.z)
        
        manager.processFaceGestureIfNeeded()
        manager.factController.updateBillboards(cameraAnchor: camAnchor, animal: manager.animalEntity)
        for spot in manager.spots {
            manager.factController.updateBillboards(cameraAnchor: camAnchor, animal: spot.activeButterfly)
        }
        
        var closestDistance = Float.infinity
        let activeSpot = manager.spots.first(where: { $0.isNear })

        for spot in manager.spots {
            let spotWorldPos = manager.parentContainer.convert(position: spot.center, to: nil)
            let spotFlat = SIMD2<Float>(spotWorldPos.x, spotWorldPos.z)
            let distance = simd_distance(cameraFlat, spotFlat)
            
            if distance < closestDistance {
                closestDistance = distance
            }

            let radiusThreshold: Float = spot.isNear ? 1.5 : 0.25

            if distance < radiusThreshold {
                if activeSpot == nil || activeSpot?.id == spot.id {
                    if !spot.isNear {
                        let isFirstDiscovery = !spot.hasVisited
                        spot.isNear = true
                        spot.hasVisited = true

                        spot.blackButterfly?.isEnabled = false
                        
                        manager.habitatController.animateCircleScale(for: spot, to: 1.0)
                        
                        if let existing = spot.activeButterfly {
                            existing.isEnabled = true
                            manager.wanderController.startWandering(existing, at: spot, anchor: manager.parentContainer)
                        } else if let template = manager.coloredButterflyTemplate {
                            manager.wanderController.spawnButterfly(at: spot, template: template, anchor: manager.parentContainer)
                        }
                        manager.habitatController.setFlowerHabitat(at: spot, count: 24, scale: 0.0012, scatteringRadius: 1.3, template: manager.flowerHabitatTemplate, anchor: manager.parentContainer)

                        if let wingAudio = manager.butterflyWingAudio {
                            spot.wingAudioController = spot.activeButterfly?.playAudio(wingAudio)
                        }

                        if isFirstDiscovery {
                            manager.triggerFeedback(tone: .positive, haptic: .success, sound: .positiveChime)
                            DispatchQueue.main.async {
                                manager.currentFactSpot = spot
                                manager.showFactSheet = true
                            }
                        }
                    }
                }
            } else {
                if spot.isNear {
                    spot.isNear = false
                    manager.wanderController.stopWandering(at: spot)
                    manager.habitatController.animateCircleScale(for: spot, to: 0.25)
                    manager.habitatController.setFlowerHabitat(at: spot, count: 6, scale: 0.0005, scatteringRadius: 0.2, template: manager.flowerHabitatTemplate, anchor: manager.parentContainer)

                    spot.wingAudioController?.stop()
                    spot.wingAudioController = nil
                }
            }
        }
        
        if let currentActive = manager.spots.first(where: { $0.isNear }) {
            if !manager.isFeedingActive {
                DispatchQueue.main.async {
                    manager.isTooFar = false
                }
            }
            for line in manager.habitatController.lineEntities {
                line.isEnabled = false
            }
            for spot in manager.spots {
                if spot.id != currentActive.id {
                    spot.circleEntity?.isEnabled = false
                    spot.blackButterfly?.isEnabled = false
                    spot.activeButterfly?.isEnabled = false
                    for flower in spot.scatteredFlowers {
                        flower.isEnabled = false
                    }
                } else {
                    spot.circleEntity?.isEnabled = true
                    spot.activeButterfly?.isEnabled = true
                    for flower in spot.scatteredFlowers {
                        flower.isEnabled = true
                    }
                }
            }
        } else {
            if !manager.isFeedingActive {
                DispatchQueue.main.async {
                    manager.isTooFar = true
                }
            }
            for line in manager.habitatController.lineEntities {
                line.isEnabled = true
            }
            for spot in manager.spots {
                spot.circleEntity?.isEnabled = true
                for flower in spot.scatteredFlowers {
                    flower.isEnabled = true
                }
                if spot.hasVisited {
                    spot.blackButterfly?.isEnabled = false
                    spot.activeButterfly?.isEnabled = true
                } else {
                    spot.blackButterfly?.isEnabled = true
                    spot.activeButterfly?.isEnabled = false
                }
            }
        }
        
        if !manager.isFeedingActive {
            manager.distanceText = String(format: "Jarak ke titik terdekat: %.2f meter", closestDistance)
        }
    }
}
