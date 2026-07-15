import SwiftUI
import RealityKit
import ARKit
import Combine


class ARManager: ObservableObject {
    @Published var distanceText: String = "Mencari objek..."
    @Published var currentAnimalName: String = ""
    @Published var isCoaching: Bool = true
    @Published var isTooFar: Bool = true
    @Published var showFacts: Bool = false
    @Published var isPlaced: Bool = false
    
    var subscriptions: [AnyCancellable] = [] 
    var eventSubscriptions: [EventSubscription] = []
    
    var cameraAnchor: AnchorEntity?
    var cubeModel: Entity?
    var baseRotation: simd_quatf = .init(angle: 0, axis: [0, 1, 0])
    
    var animalEntity: Entity? {
        return spots.first(where: { $0.isNear })?.activeButterfly
    }
    
    private var isSpawningAnimal = false
    private var distanceTimer: Timer?
    
    private var coloredButterflyTemplate: Entity?
    private var flowerHabitatTemplate: Entity?
    private var butterflyWingAudio: AudioFileResource?
    
    private var anchorRef: AnchorEntity?
    private var auraTimer: Timer?
    
    let habitatController = HabitatController()
    let wanderController = WanderController()
    let factController = FactController()
    
    let resizeController = ResizeController()
    let lifeCycleController = LifeCycleController()
    
    var spots: [ARSpot] = [
        ARSpot(id: 0, center: [-0.6, 0.05, -0.6]),
        ARSpot(id: 1, center: [ 0.6, 0.05, -0.6]),
        ARSpot(id: 2, center: [-0.6, 0.05,  0.6]),
        ARSpot(id: 3, center: [ 0.6, 0.05,  0.6])
    ]
    
    var parentContainer = Entity()
    
    func toggleFacts(show: Bool) {
        factController.toggleFacts(show: show, animal: animalEntity)
    }
    
    func spawnCube(name animalName: String, on pAnchor: AnchorEntity) {
        let loadedAnimal: Entity
        
        if animalName == "cube" {
            let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
            let material = SimpleMaterial(color: .orange, roughness: 0.2, isMetallic: true)
            loadedAnimal = ModelEntity(mesh: mesh, materials: [material])
        } else if let entity = try? Entity.load(named: animalName) {
            loadedAnimal = entity
        } else {
            print("Failed to load \(animalName). Using a fallback sphere.")
            let mesh = MeshResource.generateSphere(radius: 0.1)
            let material = SimpleMaterial(color: .orange, roughness: 0.2, isMetallic: true)
            loadedAnimal = ModelEntity(mesh: mesh, materials: [material])
        }
    }
    
    func setup(cameraAnchor: AnchorEntity, planeAnchor: AnchorEntity) {
        self.cameraAnchor = cameraAnchor
        self.anchorRef = planeAnchor
        
        planeAnchor.addChild(parentContainer)
        
        do {
            self.butterflyWingAudio = try AudioFileResource.load(
                named: "butterflyWing.wav",
                configuration: .init(shouldLoop: true)
            )
        } catch {
            print("error load butterflyWing.wav: \(error)")
        }
    }
    
    func handleTap() {
        guard let camAnchor = cameraAnchor, let anchor = anchorRef, !isPlaced else { return }
        
        let planeHeight = anchor.position(relativeTo: nil).y
        let camPos = camAnchor.position(relativeTo: nil)
        let orientation = camAnchor.orientation(relativeTo: nil)
        let forward = orientation.act(SIMD3<Float>(0, 0, -1))
        
        guard forward.y < -0.1 else { return }
        
        let t = (planeHeight - camPos.y) / forward.y
        guard t > 0 else { return }
        
        let intersectionWorld = camPos + t * forward
        let localPos = anchor.convert(position: intersectionWorld, from: nil)
        
        parentContainer.position = [localPos.x, 0, localPos.z]
        
        DispatchQueue.main.async {
            self.isPlaced = true
        }
        
        habitatController.setupHabitats(spots: spots, planeAnchor: parentContainer)
        
        auraTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.habitatController.updateAura()
        }
        
        Task {
            do {
                let template = try await Entity(named: "kepompong_2", in: nil)
                self.coloredButterflyTemplate = template.clone(recursive: true)
                
                for spot in spots {
                    let blackButterfly = template.clone(recursive: true)
                    self.habitatController.setEntityColor(blackButterfly, color: .black)
                    self.wanderController.stopAllAnimationsRecursive(blackButterfly)
                    blackButterfly.scale = SIMD3<Float>(repeating: 0.0008)
                    blackButterfly.position = spot.center
                    parentContainer.addChild(blackButterfly)
                    spot.blackButterfly = blackButterfly
                }
            } catch {
                print("error load butterfly.usdz: \(error)")
            }
            
            do {
                let flowerTemplate = try await Entity(named: "kepompong_2", in: nil)
                self.flowerHabitatTemplate = flowerTemplate
                
                for spot in spots {
                    self.habitatController.setFlowerHabitat(at: spot, count: 6, scale: 0.0005, scatteringRadius: 0.2, template: self.flowerHabitatTemplate, anchor: parentContainer)
                }
            } catch {
                print("error load flower_habitat.usdz: \(error)")
            }
        }
    }
    
    func updateScene() {
        guard let camAnchor = cameraAnchor,
              let anchor = anchorRef else { return }

        guard anchor.isAnchored else {
            self.distanceText = "scanning area sekitar"
            return
        }
        
        if !isPlaced {
            self.distanceText = "Ketuk layar untuk meletakkan area"
            DispatchQueue.main.async {
                if self.isTooFar {
                    self.isTooFar = false
                }
            }
            return
        }

        let cameraPosition = camAnchor.position(relativeTo: nil)
        let cameraFlat = SIMD2<Float>(cameraPosition.x, cameraPosition.z)
        
        // Make sticky notes always face the user
        if self.showFacts {
            factController.updateBillboards(cameraAnchor: camAnchor, animal: self.animalEntity)
        }
        
        var closestDistance = Float.infinity
        let activeSpot = spots.first(where: { $0.isNear })

        for spot in spots {
            let spotWorldPos = parentContainer.convert(position: spot.center, to: nil)
            let spotFlat = SIMD2<Float>(spotWorldPos.x, spotWorldPos.z)
            let distance = simd_distance(cameraFlat, spotFlat)
            
            if distance < closestDistance {
                closestDistance = distance
            }

            let radiusThreshold: Float = spot.isNear ? 1.5 : 0.25

            if distance < radiusThreshold {
                if activeSpot == nil || activeSpot?.id == spot.id {
                    if !spot.isNear {
                        spot.isNear = true
                        spot.hasVisited = true
                        
                        spot.blackButterfly?.isEnabled = false
                        
                        self.habitatController.animateCircleScale(for: spot, to: 1.0)
                        
                        if let existing = spot.activeButterfly {
                            existing.isEnabled = true
                            self.wanderController.startWandering(existing, at: spot, anchor: parentContainer)
                        } else if let template = self.coloredButterflyTemplate {
                            self.wanderController.spawnButterfly(at: spot, template: template, anchor: parentContainer)
                        }
                        self.habitatController.setFlowerHabitat(at: spot, count: 24, scale: 0.0012, scatteringRadius: 1.3, template: self.flowerHabitatTemplate, anchor: parentContainer)

                        if let wingAudio = self.butterflyWingAudio {
                            spot.wingAudioController = spot.activeButterfly?.playAudio(wingAudio)
                        }
                    }
                }
            } else {
                if spot.isNear {
                    spot.isNear = false
                    self.wanderController.stopWandering(at: spot)
                    self.habitatController.animateCircleScale(for: spot, to: 0.25)
                    self.habitatController.setFlowerHabitat(at: spot, count: 6, scale: 0.0005, scatteringRadius: 0.2, template: self.flowerHabitatTemplate, anchor: parentContainer)

                    spot.wingAudioController?.stop()
                    spot.wingAudioController = nil
                }
            }
        }
        
        if let currentActive = spots.first(where: { $0.isNear }) {
            DispatchQueue.main.async {
                self.isTooFar = false
            }
            for line in habitatController.lineEntities {
                line.isEnabled = false
            }
            for spot in spots {
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
            DispatchQueue.main.async {
                self.isTooFar = true
            }
            for line in habitatController.lineEntities {
                line.isEnabled = true
            }
            for spot in spots {
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
        
        self.distanceText = String(format: "Jarak ke titik terdekat: %.2f meter", closestDistance)
    }
    
    deinit {
        for spot in spots {
            spot.wanderTimer?.invalidate()
        }
        auraTimer?.invalidate()
    }
}
