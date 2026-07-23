import Foundation
import ARKit
import RealityKit
import AVFoundation
import SwiftUI

class FeedingController {
    
    private var audioPlayer: AVAudioPlayer?
    private var foodEntities: [Entity] = []
    private var foodAnchors: [AnchorEntity] = []
    private var cursorEntity: ModelEntity?
    private var draggedFoodEntity: Entity?
    private var wasGrabbing: Bool = false
    private var eatingStartedAt: Date?
    
    // Exposed variable so you can adjust how fast the butterfly catches the flower
    // Default is 0.1, lower is slower!
    var butterflySpeed: Float = 0.05
    
    private let callAnimalController = CallAnimalController()
    
    init() {
        if let url = Bundle.main.url(forResource: "bugEating", withExtension: "mp3") {
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely while eating
        }
    }
    
    func callAnimal(manager: ARManager) {
        callAnimalController.callAnimal(manager: manager)
    }

    func spawnFood(manager: ARManager) {
        guard foodEntities.isEmpty else { return } // Only spawn if empty
        
        for anchor in foodAnchors {
            anchor.removeFromParent()
        }
        foodAnchors.removeAll()
        
        guard let arView = manager.arView, let camera = manager.cameraAnchor, let animalSpot = manager.spots.first(where: { $0.isNear }) else { return }
        
        let spotWorldPos = manager.parentContainer.convert(position: animalSpot.center, to: nil)
        let floorHeight = spotWorldPos.y
        let cameraHeight = camera.position(relativeTo: nil).y
        let targetHeight = floorHeight + (cameraHeight - floorHeight) * (2.0 / 3.0)
        let pillarHeight = targetHeight - floorHeight
        
        let forward = camera.orientation(relativeTo: nil).act(SIMD3<Float>(0, 0, -1))
        let flatForward = normalize(SIMD3<Float>(forward.x, 0, forward.z))
        
        // Spawn 3 pillars with 3 different foods
        let angles: [Float] = [-(.pi / 6), 0, (.pi / 6)]
        let foodNames = ["bread-food", "flower-food", "meat-food"]
        let desiredDistance: Float = 1.0
        let animalPos = animalSpot.center
        
        Task { @MainActor in
            for (index, angle) in angles.enumerated() {
                let rotation = simd_quatf(angle: angle, axis: SIMD3<Float>(0, 1, 0))
                let direction = rotation.act(flatForward)
                
                var targetPosition = camera.position(relativeTo: nil) + direction * desiredDistance
                targetPosition.y = targetHeight
                
                // Clamp to 1.0m boundary around animalSpot (using world coordinates) to ensure it stays well inside the arena
                let animalWorldPos = spotWorldPos
                let diff = targetPosition - animalWorldPos
                let flatDiff = SIMD3<Float>(diff.x, 0, diff.z)
                if length(flatDiff) > 1.0 {
                    let clampedDiff = normalize(flatDiff) * 1.0
                    targetPosition.x = animalWorldPos.x + clampedDiff.x
                    targetPosition.z = animalWorldPos.z + clampedDiff.z
                }
                
                let anchor = AnchorEntity(world: targetPosition)
                arView.scene.addAnchor(anchor)
                self.foodAnchors.append(anchor)
                
                let foodName = foodNames[index]
                do {
                    let foodModel = try await ModelEntity(named: foodName)
                    let foodContainer = Entity()
                    foodContainer.name = foodName
                    
                    let bounds = foodModel.visualBounds(relativeTo: foodModel)
                    let width = max(bounds.extents.x, bounds.extents.z)
                    
                    if width > 0 {
                        var targetWidth: Float = 0.10
                        if foodName == "bread-food" { targetWidth = 0.07 } // Bread is 7cm
                        if foodName == "meat-food" { targetWidth = 0.13 } // Meat is 13cm
                        
                        let scale = targetWidth / width
                        foodModel.scale = SIMD3<Float>(repeating: scale)
                        
                        // Mathematically center the visual mesh perfectly onto the container's origin!
                        // This guarantees the hand attaches to the VISUAL center, not the model's empty-space origin.
                        foodModel.position = -(bounds.center * scale)
                        
                        // Sit the container on top of the pillar
                        foodContainer.position.y = (bounds.extents.y * scale) / 2.0
                    }
                    
                    foodContainer.addChild(foodModel)
                    
                    if pillarHeight > 0 {
                        let cylinderMesh = MeshResource.generateCylinder(height: pillarHeight, radius: 0.10)
                        let cylinderMaterial = SimpleMaterial(color: .white, isMetallic: false)
                        let cylinder = ModelEntity(mesh: cylinderMesh, materials: [cylinderMaterial])
                        cylinder.position.y = -(pillarHeight / 2)
                        anchor.addChild(cylinder)
                    }
                    
                    let triggerMesh = MeshResource.generateSphere(radius: 0.15)
                    let triggerMaterial = SimpleMaterial(color: .white.withAlphaComponent(0.0), isMetallic: false)
                    let trigger = ModelEntity(mesh: triggerMesh, materials: [triggerMaterial])
                    
                    foodContainer.addChild(trigger)
                    
                    self.foodEntities.append(foodContainer)
                    anchor.addChild(foodContainer)
                    
                } catch {
                    print("Failed to load \(foodName): \(error)")
                    let fallback = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [SimpleMaterial(color: .purple, isMetallic: false)])
                    fallback.name = foodName
                    self.foodEntities.append(fallback)
                    anchor.addChild(fallback)
                }
            }
        }
    }
    
    // Boundary check called every frame
    func update(manager: ARManager) {
        // Redundant boundary check removed! ArenaController handles the 1.5m boundary natively.
    }
    
    func stopFeeding() {
        for anchor in foodAnchors {
            anchor.removeFromParent()
        }
        foodAnchors.removeAll()
        foodEntities.removeAll()
        cursorEntity?.removeFromParent()
        cursorEntity = nil
        draggedFoodEntity = nil
        audioPlayer?.stop()
        eatingStartedAt = nil
    }
    
    func update(manager: ARManager, isGrabbing: Bool, normalizedPinchMidpoint: CGPoint?) {
        guard let pinchMid = normalizedPinchMidpoint, let arView = manager.arView, let frame = arView.session.currentFrame else {
            if !isGrabbing && wasGrabbing {
                dropGrabbedFood(manager: manager)
            }
            wasGrabbing = isGrabbing
            
            // Only hide the cursor if we aren't grabbing anything. 
            // If we are grabbing, keep it visible at its last known location to prevent flickering!
            if !isGrabbing {
                cursorEntity?.isEnabled = false
            }
            return
        }
        
        let orientation = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.interfaceOrientation ?? .portrait
        let transform = frame.displayTransform(for: orientation, viewportSize: arView.bounds.size)
        let invertedYPoint = CGPoint(x: pinchMid.x, y: 1.0 - pinchMid.y)
        let viewportNormalized = invertedYPoint.applying(transform)
        let screenPoint = CGPoint(x: viewportNormalized.x * arView.bounds.width,
                                  y: viewportNormalized.y * arView.bounds.height)
        
        var currentHandPosition: SIMD3<Float>?
        if let depth = getDepth(at: screenPoint, in: frame, arView: arView) {
            if let ray = arView.ray(through: screenPoint) {
                currentHandPosition = ray.origin + ray.direction * depth
            }
        } else {
            if let ray = arView.ray(through: screenPoint) {
                currentHandPosition = ray.origin + ray.direction * 0.3
            }
        }
        
        guard let handPos = currentHandPosition else {
            if !isGrabbing && wasGrabbing {
                dropGrabbedFood(manager: manager)
            }
            wasGrabbing = isGrabbing
            cursorEntity?.isEnabled = false
            return
        }
        
        if cursorEntity == nil {
            let sphere = ModelEntity(mesh: .generateSphere(radius: 0.02), materials: [SimpleMaterial(color: .yellow, isMetallic: false)])
            let cursorAnchor = AnchorEntity(world: .zero)
            cursorAnchor.addChild(sphere)
            arView.scene.addAnchor(cursorAnchor)
            self.cursorEntity = sphere
        }
        
        cursorEntity?.isEnabled = true
        cursorEntity?.position = handPos
        
        var isHovering = false
        var closestFoodToGrab: Entity?
        var closestDistance: Float = .infinity
        
        // Hover logic only applies if we aren't currently dragging
        if draggedFoodEntity == nil {
            for food in foodEntities {
                let nodePos = food.position(relativeTo: nil)
                let dx = nodePos.x - handPos.x
                let dy = nodePos.y - handPos.y
                let dz = nodePos.z - handPos.z
                
                let visualDistance = hypot(dx, dy)
                let depthDistance = abs(dz)
                
                if visualDistance < 0.20 && depthDistance < 0.25 {
                    isHovering = true
                    if visualDistance < closestDistance {
                        closestDistance = visualDistance
                        closestFoodToGrab = food
                    }
                }
            }
        } else {
            // We are already dragging, keep cursor green
            isHovering = true
        }
        
        if isHovering {
            cursorEntity?.model?.materials = [SimpleMaterial(color: .green, isMetallic: false)]
        } else if getDepth(at: screenPoint, in: frame, arView: arView) == nil {
            cursorEntity?.model?.materials = [SimpleMaterial(color: .red, isMetallic: false)]
        } else {
            cursorEntity?.model?.materials = [SimpleMaterial(color: .yellow, isMetallic: false)]
        }
        
        // Dragging Logic
        if isGrabbing && !wasGrabbing {
            if let targetFood = closestFoodToGrab {
                draggedFoodEntity = targetFood
                manager.feedingOverlayState = .grabbing
                if let cursor = cursorEntity {
                    let worldTransform = targetFood.transformMatrix(relativeTo: nil)
                    targetFood.setParent(cursor)
                    targetFood.setTransformMatrix(worldTransform, relativeTo: nil)
                }
            }
        } else if !isGrabbing && wasGrabbing {
            dropGrabbedFood(manager: manager)
        }
        
        wasGrabbing = isGrabbing
        
        if isGrabbing, let draggedFood = draggedFoodEntity {
            let animalName = manager.spots.first(where: { $0.isNear })?.animalTypeName ?? "animal"
            let foodName = draggedFood.name
            
            let dietCheck = self.checkDiet(animal: animalName, food: foodName)
            
            // Only chase the food if it is the correct diet!
            if dietCheck.isCorrect {
                manager.updateButterflyFlight(for: draggedFood, speed: butterflySpeed)
            }
            
            if let butterfly = manager.animalEntity {
                let diff = butterfly.position(relativeTo: nil) - draggedFood.position(relativeTo: nil)
                let dist = length(diff)
                
                // Butterfly is close enough to eat (20cm distance for generous collision)
                if dist < 0.20 {
                    if !dietCheck.isCorrect {
                        // Instant rejection for wrong food!
                        manager.triggerFeedback(
                            message: dietCheck.message, 
                            tone: .negative, 
                            haptic: .warning, 
                            sound: .negativeBuzz
                        )
                        dropGrabbedFood(manager: manager, showFeedback: false)
                        return
                    }
                    
                    if eatingStartedAt == nil {
                        eatingStartedAt = Date()
                        audioPlayer?.currentTime = 0
                        audioPlayer?.play()
                        manager.feedingOverlayState = .feeding
                    } else if let start = eatingStartedAt, Date().timeIntervalSince(start) > 3.0 {
                        // Success! Eaten after 3 seconds
                        draggedFood.removeFromParent()
                        if let index = foodEntities.firstIndex(of: draggedFood) {
                            foodEntities.remove(at: index)
                        }
                        self.draggedFoodEntity = nil
                        eatingStartedAt = nil
                        audioPlayer?.stop()
                        manager.feedingOverlayState = .reaching
                        
                        let animalName = manager.spots.first(where: { $0.isNear })?.animalTypeName ?? "animal"
                        let foodName = draggedFood.name
                        
                        let dietCheck = self.checkDiet(animal: animalName, food: foodName)
                        
                        manager.triggerFeedback(
                            message: dietCheck.message, 
                            tone: dietCheck.isCorrect ? .positive : .negative, 
                            haptic: dietCheck.isCorrect ? .success : .warning, 
                            sound: dietCheck.isCorrect ? .positiveChime : .negativeBuzz
                        )
                        
                        // Respawn if both eaten
                        if foodEntities.isEmpty {
                            spawnFood(manager: manager)
                        }
                    }
                } else {
                    audioPlayer?.stop()
                    eatingStartedAt = nil
                    if draggedFoodEntity != nil {
                        manager.feedingOverlayState = .grabbing
                    }
                }
            }
        }
    }
    
    
    private func checkDiet(animal: String, food: String) -> (isCorrect: Bool, message: String) {
        let lowerAnimal = animal.lowercased()
        let lowerFood = food.lowercased()
        
        var diet = "Omnivore"
        var allowedFoods: [String] = []
        var eatsDescription = "both plants and meat"
        
        if lowerAnimal.contains("butterfly") {
            diet = "Herbivore"
            allowedFoods = ["flower-food"]
            eatsDescription = "nectar from flowers"
        } else if lowerAnimal.contains("lion") || lowerAnimal.contains("wolf") {
            diet = "Carnivore"
            allowedFoods = ["meat-food"]
            eatsDescription = "meat"
        } else if lowerAnimal.contains("goat") || lowerAnimal.contains("herbivore") {
            diet = "Herbivore"
            allowedFoods = ["flower-food", "bread-food"]
            eatsDescription = "plants and bread"
        } else {
            // Fallback
            allowedFoods = ["bread-food", "flower-food", "meat-food"]
        }
        
        let isCorrect = allowedFoods.contains(lowerFood)
        let cleanFoodName = lowerFood.replacingOccurrences(of: "-food", with: "")
        
        if isCorrect {
            return (true, "Yum! Great Choice! I'm a \(diet), so I eat \(eatsDescription).")
        } else {
            return (false, "Eww... I'm a \(diet), I don't eat \(cleanFoodName)!")
        }
    }
    
    private func dropGrabbedFood(manager: ARManager, showFeedback: Bool = true) {
        manager.feedingOverlayState = .reaching
        if let draggedFood = draggedFoodEntity {
            draggedFood.removeFromParent()
            if let index = foodEntities.firstIndex(of: draggedFood) {
                foodEntities.remove(at: index)
            }
            
            if showFeedback {
                let cleanFoodName = draggedFood.name.replacingOccurrences(of: "-food", with: "")
                manager.triggerFeedback(message: "Oh no! You dropped the \(cleanFoodName)!", tone: .negative, haptic: .warning, sound: .negativeBuzz)
            }
            
            self.draggedFoodEntity = nil // FIX: Reset dragged entity so another can be grabbed!
            
            // Respawn if both dropped/eaten
            if foodEntities.isEmpty {
                spawnFood(manager: manager)
            }
        }
        audioPlayer?.pause()
        audioPlayer?.currentTime = 0
        eatingStartedAt = nil
    }
    
    private func getDepth(at screenPoint: CGPoint, in frame: ARFrame, arView: ARView) -> Float? {
        guard let sceneDepth = frame.sceneDepth else { return nil }
        let depthMap = sceneDepth.depthMap
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        let viewSize = arView.bounds.size
        
        let orientation = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.interfaceOrientation ?? .portrait
        let transform = frame.displayTransform(for: orientation, viewportSize: viewSize).inverted()
        let normalizedPoint = CGPoint(x: screenPoint.x / viewSize.width, y: screenPoint.y / viewSize.height)
        let depthPoint = normalizedPoint.applying(transform)
        
        let pixelX = Int(depthPoint.x * CGFloat(width))
        let pixelY = Int(depthPoint.y * CGFloat(height))
        
        guard pixelX >= 0 && pixelX < width && pixelY >= 0 && pixelY < height else { return nil }
        
        if CVPixelBufferGetPixelFormatType(depthMap) == kCVPixelFormatType_DepthFloat32 {
            if let baseAddress = CVPixelBufferGetBaseAddress(depthMap) {
                let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
                var minDepth: Float = .infinity
                for dy in -2...2 {
                    for dx in -2...2 {
                        let sampleX = pixelX + dx
                        let sampleY = pixelY + dy
                        if sampleX >= 0 && sampleX < width && sampleY >= 0 && sampleY < height {
                            let rowData = baseAddress.advanced(by: sampleY * bytesPerRow)
                            let depth = rowData.assumingMemoryBound(to: Float32.self)[sampleX]
                            if depth > 0 && depth < minDepth {
                                minDepth = depth
                            }
                        }
                    }
                }
                return minDepth == .infinity ? nil : minDepth
            }
        }
        return nil
    }
}
