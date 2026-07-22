import SwiftUI
import RealityKit
import ARKit
import Combine


class ARManager: NSObject, ObservableObject {
    @Published var distanceText: String = "Find me!stop "
    @Published var currentAnimalName: String = ""
    @Published var isCoaching: Bool = true
    @Published var isTooFar: Bool = true
    @Published var showFacts: Bool = false
    @Published var feedbackEvent: FeedbackEvent?
    @Published var isPlaced: Bool = false
    // True when the camera center raycast hits a valid floor plane in real-time.
    // Drives the green indicator and dynamic placement label in ContentView.
    @Published var isFloorTargeted: Bool = false
    
    @Published var isFeedingActive: Bool = false
    @Published var feedingOverlayState: FeedingOverlayState = .reaching

    @Published var showFactSheet: Bool = false
    @Published var showFeedingGuide: Bool = false
    @Published var isFactQuestionActive: Bool = false
    @Published var isLockedNearActive: Bool = false
    @Published var isFirstDiscoveryFact: Bool = false
    @Published var currentFactSpot: ARSpot? = nil
    @Published var currentLifeCyclePhase: Int = 1

    
    var subscriptions: [AnyCancellable] = [] 
    var eventSubscriptions: [EventSubscription] = []
    
    var cameraAnchor: AnchorEntity?
    var cubeModel: Entity?
    var baseRotation: simd_quatf = .init(angle: 0, axis: [0, 1, 0])
    // Set once by ARViewContainer. Used by PlacementController for tap raycast.
    weak var arView: ARView?
    
    var animalEntity: Entity? {
        return spots.first(where: { $0.isNear })?.animalModel
    }
    
    private var isSpawningAnimal = false
    private var distanceTimer: Timer?
    
    var coloredButterflyTemplate: Entity?
    var flowerHabitatTemplate: Entity?
    var grassHabitatTemplate: Entity?
    var butterflyWingAudio: AudioFileResource?
    private var positiveChimeAudio: AudioFileResource?
    private var negativeBuzzAudio: AudioFileResource?
    
    var butterflyTemplate: ModelEntity?
    
    var anchorRef: AnchorEntity?
    var faceAnchor: AnchorEntity?
    var auraTimer: Timer?
    var arSession: ARSession?
    
    let habitatController = HabitatController()
    let wanderController = WanderController()
    let factController = FactController()
    
    let resizeController = ResizeController()
    let lifeCycleController = LifeCycleController()
    // Feeding feature controller
    lazy var feedingController: FeedingController = FeedingController()
    
    // Core placement & exploration controllers
    lazy var placementController: PlacementController = PlacementController(manager: self)
    lazy var arenaController: ArenaController = ArenaController(manager: self)
    let headGestureController = HeadGestureController()
    
    var spots: [ARSpot] = [
        ARSpot(id: 0, center: [-1.1, 0.05, -1.1]),
        ARSpot(id: 1, center: [ 1.1, 0.05, -1.1]),
        ARSpot(id: 2, center: [-1.1, 0.05,  1.1]),
        ARSpot(id: 3, center: [ 1.1, 0.05,  1.1])
    ]
    
    var parentContainer = Entity()
    
    func toggleFacts(show: Bool) {
        let typeName = spots.first(where: { $0.isNear })?.animalTypeName ?? "butterfly"
        factController.toggleFacts(show: show, animal: animalEntity, animalTypeName: typeName) 
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
    
    func createSpatialAudio(audioName: String) -> Entity {
        let audioSource = Entity()
        
        audioSource.spatialAudio = SpatialAudioComponent(
            gain: -10,
            directLevel: .zero,
            reverbLevel: .zero,
            directivity: .beam(focus: 0.3),
            distanceAttenuation: .rolloff(factor: 3.0)
        )
        
        do {
            let resource = try AudioFileResource.load(named: audioName, configuration: .init(shouldLoop: true))
            audioSource.playAudio(resource)
        } catch {
            print("Error loading audio file: \(error.localizedDescription)")
        }
        
        return audioSource
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
    
    func resetPlacement() {
        auraTimer?.invalidate()
        auraTimer = nil
        
        for spot in spots {
            spot.wanderTimer?.invalidate()
            spot.wanderTimer = nil
//            spot.wingAudioController?.stop()
//            spot.wingAudioController = nil
            
//            spot.spatialAudioEntity?.removeFromParent()
//            spot.spatialAudioEntity = nil
            
            spot.animalModel?.removeFromParent()
            spot.animalModel = nil
            spot.reflectiveAnimal?.removeFromParent()
            spot.reflectiveAnimal = nil
            
            for flower in spot.scatteredFlowers {
                flower.removeFromParent()
            }
            spot.scatteredFlowers.removeAll()
            
            for grass in spot.scatteredGrass {
                grass.removeFromParent()
            }
            spot.scatteredGrass.removeAll()
            
            
            
            spot.isNear = false
            spot.hasVisited = false
        }
        
        parentContainer.children.removeAll()
        showFactSheet = false
        isFactQuestionActive = false
        currentFactSpot = nil
        showFacts = false
        isTooFar = true
        isPlaced = false
    }

    func setup(cameraAnchor: AnchorEntity, planeAnchor: AnchorEntity) {
        self.cameraAnchor = cameraAnchor
        self.anchorRef = planeAnchor
        
        planeAnchor.addChild(parentContainer)
        setupHeadGestureListener()
        
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
    
    // ARManager.swift
//    func heightOffset(for animalTypeName: String) -> Float {
//        switch animalTypeName {
//        case "butterfly": return 2.5
//        case "Lioness": return 0.01
//        case "Wolf": return 0.0
//        case "MountainGoat": return 0.01
//        default: return 0.2
//        }
//    }
    
    func heightOffset(for spot: ARSpot) -> Float {
        if spot.animalTypeName == "butterfly" {
            return 0.95 // Ketinggian terbang kupu-kupu dari ground
        } else {
            return spot.groundOffset 
        }
    }
    
    func flightExtra(for animalTypeName: String) -> Float {
        switch animalTypeName {
        case "butterfly": return 1.5   // flies above the flowers
        default: return 0              // ground animals: no extra lift
        }
    }
    
    deinit {
        for spot in spots {
            spot.wanderTimer?.invalidate()
        }
        auraTimer?.invalidate()
    }
}
