import SwiftUI
import RealityKit
import ARKit
import Combine

enum FeedingState {
    case idle
    case carryingFood(Entity)
}

enum FeedingOverlayState {
    case reaching
    case grabbing
}

class ARManager: ObservableObject {
    @Published var distanceText: String = "Find me!stop"
    @Published var currentAnimalName: String = ""
    @Published var isCoaching: Bool = true
    @Published var isTooFar: Bool = true
    @Published var showFacts: Bool = false
    @Published var feedbackEvent: FeedbackEvent?
    @Published var isPlaced: Bool = false
    
    @Published var isFeedingActive: Bool = false
    @Published var feedingOverlayState: FeedingOverlayState = .reaching
    var feedingState: FeedingState = .idle
    var spawnedFoodEntities: [Entity] = []
    
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
    
    var coloredButterflyTemplate: Entity?
    private var flowerHabitatTemplate: Entity?
    var butterflyWingAudio: AudioFileResource?
    private var positiveChimeAudio: AudioFileResource?
    private var negativeBuzzAudio: AudioFileResource?
    
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

    /// Single shared entry point for banner + haptic + sound feedback, so
    /// every mode speaks the same "language" instead of rolling its own.
    /// Pass `message: nil` for minor actions that shouldn't pop a banner
    /// (e.g. a toggle), and `sound: nil` when a haptic tick is enough.
    func triggerFeedback(message: String? = nil, tone: FeedbackTone, haptic: FeedbackHaptic, sound: FeedbackSound? = nil) {
        let event = FeedbackEvent(message: message, tone: tone, haptic: haptic, sound: sound)
        DispatchQueue.main.async {
            self.feedbackEvent = event
        }
        playFeedbackSound(sound)
    }

    /// Feedback chimes/buzzes are UI cues, not diegetic world sound, so they
    /// play on the camera anchor with an AmbientAudioComponent (no
    /// distance/direction attenuation) rather than spatialized like the
    /// per-spot butterfly wing audio.
    private func playFeedbackSound(_ sound: FeedbackSound?) {
        guard let sound, let camera = cameraAnchor else { return }

        let resource: AudioFileResource?
        switch sound {
        case .positiveChime: resource = positiveChimeAudio
        case .negativeBuzz: resource = negativeBuzzAudio
        }

        guard let resource else { return }
        if !camera.components.has(AmbientAudioComponent.self) {
            camera.components.set(AmbientAudioComponent())
        }
        camera.playAudio(resource)
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

        do {
            self.positiveChimeAudio = try AudioFileResource.load(named: "positveChime.wav")
        } catch {
            print("error load positveChime.wav: \(error)")
        }

        do {
            self.negativeBuzzAudio = try AudioFileResource.load(named: "negativeBuzz.mp3")
        } catch {
            print("error load negativeBuzz.mp3: \(error)")
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
                let template = try await Entity(named: "butterfly", in: nil)
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
                let flowerTemplate = try await Entity(named: "flower_habitat", in: nil)
                self.flowerHabitatTemplate = flowerTemplate
                
                for spot in spots {
                    self.habitatController.setFlowerHabitat(at: spot, count: 6, scale: 0.0005, scatteringRadius: 0.2, template: self.flowerHabitatTemplate, anchor: parentContainer)
                }
            } catch {
                print("error load flower_habitat.usdz: \(error)")
            }
        }
    }
    
    func startFeedingMode() {
        guard let spot = spots.first(where: { $0.isNear }), isPlaced else { return }
        
        cleanLeftoverFood()
        
        isFeedingActive = true
        feedingOverlayState = .reaching
        feedingState = .idle
        
        let mesh = MeshResource.generateSphere(radius: 0.05)
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .orange)
        material.roughness = 0.2
        material.metallic = 0.0
        
        for _ in 0..<3 {
            let angle = Float.random(in: 0..<(2 * .pi))
            let radius = Float.random(in: 0.4...0.8)
            let food = ModelEntity(mesh: mesh, materials: [material])
            food.name = "food"
            food.position = [spot.center.x + radius * cos(angle), 0.05, spot.center.z + radius * sin(angle)]
            parentContainer.addChild(food)
            spawnedFoodEntities.append(food)
        }
        
        self.distanceText = "Walk close to a food sphere to pick it up!"
    }
    
    func stopFeedingMode() {
        isFeedingActive = false
        cleanLeftoverFood()
        feedingState = .idle
        self.distanceText = ""
    }
    
    private func cleanLeftoverFood() {
        for food in spawnedFoodEntities {
            food.removeFromParent()
        }
        spawnedFoodEntities.removeAll()
        
        if case .carryingFood(let food) = feedingState {
            food.removeFromParent()
        }
    }
    
    private func updateFeedingGameplay() {
        guard let camAnchor = cameraAnchor, let spot = spots.first(where: { $0.isNear }) else { return }
        let cameraPos = camAnchor.position(relativeTo: nil)
        let cameraFlat = SIMD2<Float>(cameraPos.x, cameraPos.z)
        
        switch feedingState {
        case .idle:
            var pickedUpFood: Entity? = nil
            for food in spawnedFoodEntities {
                let foodPos = food.position(relativeTo: nil)
                let foodFlat = SIMD2<Float>(foodPos.x, foodPos.z)
                let dist = simd_distance(cameraFlat, foodFlat)
                if dist < 0.35 {
                    pickedUpFood = food
                    break
                }
            }
            
            if let food = pickedUpFood {
                food.removeFromParent()
                if let index = spawnedFoodEntities.firstIndex(of: food) {
                    spawnedFoodEntities.remove(at: index)
                }
                
                camAnchor.addChild(food)
                food.position = [0, -0.04, -0.35]
                
                feedingState = .carryingFood(food)
                DispatchQueue.main.async {
                    self.feedingOverlayState = .grabbing
                    self.distanceText = "Food picked up! Walk close to the butterfly."
                }
                
                #if os(iOS)
                let feedback = UIImpactFeedbackGenerator(style: .medium)
                feedback.prepare()
                feedback.impactOccurred()
                #endif
            }
            
        case .carryingFood(let food):
            let spotWorldPos = parentContainer.convert(position: spot.center, to: nil)
            let spotFlat = SIMD2<Float>(spotWorldPos.x, spotWorldPos.z)
            let dist = simd_distance(cameraFlat, spotFlat)
            if dist < 0.15 {
                food.removeFromParent()
                feedingState = .idle
                
                DispatchQueue.main.async {
                    self.feedingOverlayState = .reaching
                    if self.spawnedFoodEntities.isEmpty {
                        self.distanceText = "Yum! Butterfly is full! 🦋✨"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.stopFeedingMode()
                        }
                    } else {
                        self.distanceText = "Yum! Find more food on the floor!"
                    }
                }
                
                #if os(iOS)
                let feedback = UINotificationFeedbackGenerator()
                feedback.prepare()
                feedback.notificationOccurred(.success)
                #endif
            }
        }
    }
    
    func updateScene() {
        guard let camAnchor = cameraAnchor,
              let anchor = anchorRef else { return }

        guard anchor.isAnchored else {
            self.distanceText = "Scanning surrounding area..."
            return
        }
        
        if !isPlaced {
            self.distanceText = "Tap screen to place the area"
            DispatchQueue.main.async {
                if self.isTooFar {
                    self.isTooFar = false
                }
            }
            return
        }
        
        if isFeedingActive {
            if spots.first(where: { $0.isNear }) == nil {
                stopFeedingMode()
                return
            }
            updateFeedingGameplay()
        }

        let cameraPosition = camAnchor.position(relativeTo: nil)
        let cameraFlat = SIMD2<Float>(cameraPosition.x, cameraPosition.z)
        
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
                        let isFirstDiscovery = !spot.hasVisited
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

                        if isFirstDiscovery {
                            self.triggerFeedback(tone: .positive, haptic: .success, sound: .positiveChime)
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
            if !isFeedingActive {
                DispatchQueue.main.async {
                    self.isTooFar = false
                }
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
            if !isFeedingActive {
                DispatchQueue.main.async {
                    self.isTooFar = true
                }
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
        
        if !isFeedingActive {
            self.distanceText = String(format: "Jarak ke titik terdekat: %.2f meter", closestDistance)
        }
    }
    
    deinit {
        for spot in spots {
            spot.wanderTimer?.invalidate()
        }
        auraTimer?.invalidate()
    }
}
