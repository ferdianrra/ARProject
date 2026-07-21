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
            manager.factController.updateBillboards(cameraAnchor: camAnchor, animal: spot.animalModel)
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
                        
                        spot.reflectiveAnimal?.isEnabled = false
                        
                        manager.habitatController.animateCircleScale(for: spot, to: 1.0)
                        
                        if spot.animalTypeName == "butterfly" {
                            // --- KHUSUS BUTTERFLY: Boleh terbang & muter ---
                            if let existing = spot.animalModel {
                                existing.isEnabled = true
                                manager.wanderController.startWandering(existing, at: spot, anchor: manager.parentContainer, yHeight: manager.heightOffset(for: spot))
                            } else if let template = spot.animalTemplate {
                                manager.wanderController.spawnButterfly(at: spot, template: template, anchor: manager.parentContainer, yHeight: manager.heightOffset(for: spot))
                            }
                        } else {
                            // --- KHUSUS HEWAN DARAT (Lioness, Wolf, Goat): Cuma di-enable & diam di tempat ---
                            if let existing = spot.animalModel {
                                existing.isEnabled = true
                                existing.position = SIMD3<Float>(spot.center.x, spot.groundOffset, spot.center.z)
                            } else if let template = spot.animalTemplate {
                                let animal = template.clone(recursive: true)
                                animal.position = SIMD3<Float>(spot.center.x, spot.groundOffset, spot.center.z)
                                manager.parentContainer.addChild(animal)
                                spot.animalModel = animal
                            }
                        }
                        
                        // Audio untuk semua hewan
                        if !spot.audioName.isEmpty, let animalModel = spot.animalModel {
                            let audioEntity = manager.createSpatialAudio(audioName: spot.audioName)
                            animalModel.addChild(audioEntity)
                            spot.spatialAudioEntity = audioEntity
                        }
                        
                        manager.habitatController.setFlowerHabitat(at: spot, count: 24, scale: 0.0028, scatteringRadius: 1.3, template: manager.flowerHabitatTemplate, anchor: manager.parentContainer)
                        
                        if isFirstDiscovery {
                            manager.triggerFeedback(tone: .positive, haptic: .success, sound: .positiveChime)
                            DispatchQueue.main.async {
                                manager.isFirstDiscoveryFact = true
                                manager.currentFactSpot = spot
                                manager.showFactSheet = true
                            }
                        }
                    }
                }
            } else {
                if spot.isNear {
                    spot.isNear = false
                    manager.wanderController.stopWandering(at: spot, yHeight: manager.heightOffset(for: spot))
                    manager.habitatController.animateCircleScale(for: spot, to: 0.25)
                    manager.habitatController.setFlowerHabitat(at: spot, count: 6, scale: 0.0012, scatteringRadius: 0.2, template: manager.flowerHabitatTemplate, anchor: manager.parentContainer)
                    
                    // Re-enable black butterfly silhouette when out of arena
                    spot.reflectiveAnimal?.isEnabled = true
                    
                    //                    spot.wingAudioController?.stop()
                    //                    spot.wingAudioController = nil
                    
//                    spot.spatialAudioEntity?.removeFromParent()
//                    spot.spatialAudioEntity = nil
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
                    spot.reflectiveAnimal?.isEnabled = false
                    spot.animalModel?.isEnabled = false
                    for flower in spot.scatteredFlowers {
                        flower.isEnabled = false
                    }
                } else {
                    spot.circleEntity?.isEnabled = true
                    spot.animalModel?.isEnabled = true
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
                    spot.reflectiveAnimal?.isEnabled = false
                    spot.animalModel?.isEnabled = true
                } else {
                    spot.reflectiveAnimal?.isEnabled = true
                    spot.animalModel?.isEnabled = false
                }
            }
        }
        
        if !manager.isFeedingActive {
            manager.distanceText = String(format: "Jarak ke titik terdekat: %.2f meter", closestDistance)
        }
    }
}
