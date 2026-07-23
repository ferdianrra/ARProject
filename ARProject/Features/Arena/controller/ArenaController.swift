import RealityKit
import Foundation

class ArenaController {
    private weak var manager: ARManager?
    
    init(manager: ARManager) {
        self.manager = manager
    }
    
    func checkProximity() {
        guard let manager = manager,
              let camAnchor = manager.cameraAnchor,
              manager.isPlaced else { return }
        
        if manager.isFeedingActive {
            if manager.spots.first(where: { $0.isNear }) == nil {
                manager.stopFeedingMode()
                return
            }
            manager.feedingController.update(manager: manager)
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

//            if spot.animalTypeName != "butterfly" {
//                let isButterflyActive = manager.spots.first(where: { $0.animalTypeName == "butterfly" })?.isNear ?? false
//                if distance < 0.6 && !isButterflyActive {
//                    if !spot.isLockedNear {
//                        spot.isLockedNear = true
//                        manager.triggerFeedback(message: nil, tone: .negative, haptic: .warning, sound: .negativeBuzz)
//                    }
//                } else {
//                    spot.isLockedNear = false
//                }
//                continue
//            }

            let radiusThreshold: Float = spot.isNear ? 1.5 : 0.6
            
            if distance < radiusThreshold {
                if activeSpot == nil || activeSpot?.id == spot.id {
                    if !spot.isNear {
                        let isFirstDiscovery = !spot.hasVisited
                        spot.isNear = true
                        spot.hasVisited = true
                        
                        spot.reflectiveAnimal?.isEnabled = false
                        
                        manager.habitatController.animateCircleScale(for: spot, to: 1.0)
                        
                        
                        if spot.animalTypeName == "butterfly" {
                            if let existing = spot.animalModel {
                                existing.isEnabled = true
                                manager.wanderController.startWandering(existing, at: spot, anchor: manager.parentContainer, yHeight: manager.heightOffset(for: spot))
                            } else if let template = spot.animalTemplate {
                                manager.wanderController.spawnButterfly(at: spot, template: template, anchor: manager.parentContainer, yHeight: manager.heightOffset(for: spot))
                            }
                        } else {
                            if let existing = spot.animalModel {
                                existing.isEnabled = true
                                existing.position = SIMD3<Float>(spot.center.x, spot.groundOffset, spot.center.z)
                                
                                existing.scale = spot.baseScale
                                var grown = existing.transform
                                grown.scale = spot.baseScale * 2.0
                                existing.move(to: grown, relativeTo: existing.parent, duration: 0.4, timingFunction: .easeInOut)
                            } else if let template = spot.animalTemplate {
                                let animal = template.clone(recursive: true)
                                animal.position = SIMD3<Float>(spot.center.x, spot.groundOffset, spot.center.z)
                                manager.parentContainer.addChild(animal)
                                spot.animalModel = animal
                                
                                var grown = animal.transform
                                grown.scale = spot.baseScale * 2
                                animal.move(to: grown, relativeTo: animal.parent, duration: 0.4, timingFunction: .easeInOut)
                            }
                        }
                        
//                        if !spot.audioName.isEmpty, let animalModel = spot.animalModel {
//                            if let audioEntity = spot.spatialAudioEntity {
//                                audioEntity.removeFromParent()
//                                animalModel.addChild(audioEntity)
//                            } else {
//                                let audioEntity = manager.createSpatialAudio(audioName: spot.audioName)
//                                animalModel.addChild(audioEntity)
//                                spot.spatialAudioEntity = audioEntity
//                            }
//                        }
                        
                        if spot.animalTypeName == "butterfly" {
                            manager.habitatController.setFlowerHabitat(at: spot, count: 24, scale: 0.0028, scatteringRadius: 1.3, template: manager.flowerHabitatTemplate, anchor: manager.parentContainer)
                        } else {
                            manager.habitatController.setGrassHabitat(at: spot, count: 24, scale: 0.0028, scatteringRadius: 1.3, template: manager.grassHabitatTemplate, anchor: manager.parentContainer)
                        }
                
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
                    manager.isCallingAnimal = false
                    manager.wanderController.stopWandering(at: spot, yHeight: manager.heightOffset(for: spot))
                    manager.habitatController.animateCircleScale(for: spot, to: 0.25)
                    if spot.animalTypeName == "butterfly" {
                        manager.habitatController.setFlowerHabitat(at: spot, count: 6, scale: 0.0006, scatteringRadius: 0.2, template: manager.flowerHabitatTemplate, anchor: manager.parentContainer)
                    } else {
                        manager.habitatController.setGrassHabitat(at: spot, count: 6, scale: 0.0006, scatteringRadius: 0.2, template: manager.grassHabitatTemplate, anchor: manager.parentContainer)
                    }
                    
                    if spot.animalTypeName != "butterfly", let animalModel = spot.animalModel {
                        var restoredTransform = animalModel.transform
                        restoredTransform.scale = spot.baseScale
                        animalModel.move(to: restoredTransform, relativeTo: animalModel.parent, duration: 0.4, timingFunction: .easeInOut)
                    }
                    
                    if let audioEntity = spot.spatialAudioEntity, let reflective = spot.reflectiveAnimal {
                        audioEntity.removeFromParent()
                        reflective.addChild(audioEntity)
                    }
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
                    for grass in spot.scatteredGrass {
                        grass.isEnabled = false
                    }
                } else {
                    spot.circleEntity?.isEnabled = true
                    spot.animalModel?.isEnabled = true
                    for flower in spot.scatteredFlowers {
                        flower.isEnabled = true
                    }
                    for grass in spot.scatteredGrass {
                        grass.isEnabled = true
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
                for grass in spot.scatteredGrass {
                    grass.isEnabled = true
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
        
        let anyLockedNear = manager.spots.contains(where: { $0.isLockedNear })
        if manager.isLockedNearActive != anyLockedNear {
            DispatchQueue.main.async {
                manager.isLockedNearActive = anyLockedNear
            }
        }
    }
}
