import RealityKit
import Combine
import SwiftUI


enum FeedingState {
    case idle
    case carryingFood(Entity)
}

enum FeedingOverlayState {
    case reaching
    case grabbing
}

final class FeedingController {
    // MARK: - Public state (observable untuk UI)
    @Published var isActive: Bool = false
    @Published var distanceText: String = ""

    // MARK: - Private storage
    private weak var manager: ARManager?
    private var spots: [ARSpot] = []
    private var spawnedFood: [Entity] = []
    private var feedingState: FeedingState = .idle

    // MARK: - Init
    init(manager: ARManager, spots: [ARSpot]) {
        self.manager = manager
        self.spots = spots
    }

    // MARK: - Public API
    func startFeeding() {
        guard let spot = spots.first(where: { $0.isNear }) else { return }
        cleanUpFood()
        isActive = true
        manager?.isFeedingActive = true
        feedingState = .idle
        spawnFood(near: spot)
        distanceText = "Walk close to a food sphere to pick it up!"
        manager?.distanceText = distanceText
    }

    func stopFeeding() {
        isActive = false
        manager?.isFeedingActive = false
        cleanUpFood()
        distanceText = ""
        manager?.distanceText = distanceText
        feedingState = .idle
    }

    /// Dipanggil tiap frame dari `ARManager.updateScene()`.
    func update(cameraAnchor: AnchorEntity?) {
        guard isActive, let cam = cameraAnchor, let spot = spots.first(where: { $0.isNear }) else { return }
        updateFeedingGameplay(camera: cam, spot: spot)
    }

    // MARK: - Private helpers (dipindahkan dari ARManager)
    private func spawnFood(near spot: ARSpot) {
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
            manager?.parentContainer.addChild(food)
            spawnedFood.append(food)
        }
    }

    private func cleanUpFood() {
        for food in spawnedFood { food.removeFromParent() }
        spawnedFood.removeAll()
        if case .carryingFood(let food) = feedingState {
            food.removeFromParent()
        }
    }

    private func updateFeedingGameplay(camera camAnchor: AnchorEntity, spot: ARSpot) {
        let cameraPos = camAnchor.position(relativeTo: nil)
        let cameraFlat = SIMD2<Float>(cameraPos.x, cameraPos.z)
        switch feedingState {
        case .idle:
            var pickedUpFood: Entity? = nil
            for food in spawnedFood {
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
                if let idx = spawnedFood.firstIndex(of: food) { spawnedFood.remove(at: idx) }
                camAnchor.addChild(food)
                food.position = [0, -0.04, -0.35]
                feedingState = .carryingFood(food)
                manager?.feedingOverlayState = .grabbing
                manager?.distanceText = "Food picked up! Walk close to the animal."
                // Haptic (iOS only)
                #if os(iOS)
                let feedback = UIImpactFeedbackGenerator(style: .medium)
                feedback.prepare()
                feedback.impactOccurred()
                #endif
            }
        case .carryingFood(let food):
            let spotWorldPos = manager?.parentContainer.convert(position: spot.center, to: nil) ?? SIMD3<Float>(0,0,0)
            let spotFlat = SIMD2<Float>(spotWorldPos.x, spotWorldPos.z)
            let dist = simd_distance(cameraFlat, spotFlat)
            if dist < 0.15 {
                food.removeFromParent()
                feedingState = .idle
                manager?.feedingOverlayState = .reaching
                if spawnedFood.isEmpty {
                    manager?.distanceText = "Yum! The animal is full! 🐾✨"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.stopFeeding()
                    }
                } else {
                    manager?.distanceText = "Yum! Find more food on the floor!"
                }
                #if os(iOS)
                let feedback = UINotificationFeedbackGenerator()
                feedback.prepare()
                feedback.notificationOccurred(.success)
                #endif
            }
        }
    }
}
