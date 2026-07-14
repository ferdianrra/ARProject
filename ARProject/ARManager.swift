import SwiftUI
import RealityKit
import ARKit
import Combine

class ARManager: ObservableObject {
    @Published var distanceText: String = "Mencari objek..."
    @Published var currentAnimalName: String = ""
    
    var cameraAnchor: AnchorEntity?
    var cubeModel: Entity?
    var baseRotation: simd_quatf = .init(angle: 0, axis: [0, 1, 0])
    var animalEntity: Entity?
    
    private var isSpawningAnimal = false
    private var isNear = false
    private var hasEnteredOnce = false
    
    private var coloredButterflyTemplate: Entity?
    private var flowerHabitatTemplate: Entity?
    
    private var smallBlackButterfly: Entity?
    private var activeButterfly: Entity?
    private var scatteredButterflies: [Entity] = []
    private var scatteredFlowers: [Entity] = []
    
    private var anchorRef: AnchorEntity?
    private var wanderTimer: Timer?
    
    func setup(cameraAnchor: AnchorEntity, planeAnchor: AnchorEntity) {
        self.cameraAnchor = cameraAnchor
        self.anchorRef = planeAnchor
        
        Task {
            do {
                let template = try await Entity(named: "butterfly", in: nil)
                self.coloredButterflyTemplate = template.clone(recursive: true)
                
                let blackButterfly = template.clone(recursive: true)
                self.setEntityColor(blackButterfly, color: .black)
                self.stopAllAnimationsRecursive(blackButterfly)
                blackButterfly.scale = SIMD3<Float>(repeating: 0.001)
                blackButterfly.position = [0, 0.05, 0]
                planeAnchor.addChild(blackButterfly)
                self.smallBlackButterfly = blackButterfly
            } catch {
                print("error load butterfly.usdz: \(error)")
            }
            
            do {
                let flowerTemplate = try await Entity(named: "flower_habitat", in: nil)
                self.flowerHabitatTemplate = flowerTemplate
            } catch {
                print("error load flower_habitat.usdz: \(error)")
            }
        }
    }
    
    func updateScene() {
        guard let camAnchor = cameraAnchor,
              let anchor = anchorRef,
              let referenceButterfly = smallBlackButterfly else { return }

        guard anchor.isAnchored else {
            self.distanceText = "Mencari area..."
            return
        }

        let modelPosition = referenceButterfly.position(relativeTo: nil)
        let cameraPosition = camAnchor.position(relativeTo: nil)

        let modelFlat = SIMD2<Float>(modelPosition.x, modelPosition.z)
        let cameraFlat = SIMD2<Float>(cameraPosition.x, cameraPosition.z)
        let distance = simd_distance(modelFlat, cameraFlat)

        self.distanceText = String(format: "Jarak: %.2f meter", distance)

        let radiusThreshold: Float = 1.0

        if distance < radiusThreshold {
            if !self.isNear {
                self.isNear = true
                self.hasEnteredOnce = true
                
                self.smallBlackButterfly?.isEnabled = false
                
                if let existing = self.activeButterfly {
                    existing.isEnabled = true
                    self.startWandering(existing, anchor: anchor, radius: radiusThreshold)
                } else {
                    self.spawnButterfly(around: anchor, radius: radiusThreshold)
                }
                self.setFlowerHabitat(around: anchor, radius: radiusThreshold, count: 24, scale: 0.002)
            }
        } else {
            if !self.hasEnteredOnce {
                self.smallBlackButterfly?.isEnabled = true
                self.activeButterfly?.isEnabled = false
            } else {
                self.smallBlackButterfly?.isEnabled = false
                self.activeButterfly?.isEnabled = true
            }
            if self.isNear {
                self.isNear = false
                self.stopWandering()
                self.setFlowerHabitat(around: anchor, radius: radiusThreshold, count: 6, scale: 0.0008)
            }
        }
    }
    
    private func spawnButterfly(around anchor: AnchorEntity, radius: Float) {
        guard let template = coloredButterflyTemplate else { return }
        let butterfly = template.clone(recursive: true)
        butterfly.scale = SIMD3<Float>(repeating: 0.002)
        let point = randomPointInCircle(radius: radius)
        butterfly.position = [point.x, 0.35, point.y]
        anchor.addChild(butterfly)
        playAllAnimationsRecursive(butterfly)
        self.activeButterfly = butterfly
        startWandering(butterfly, anchor: anchor, radius: radius)
    }
    
    private func startWandering(_ butterfly: Entity, anchor: AnchorEntity, radius: Float) {
        playAllAnimationsRecursive(butterfly)
        moveToNewRandomPoint(butterfly, anchor: anchor, radius: radius)

        let interval: TimeInterval = 4.0
        wanderTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self, weak butterfly] _ in
            guard let self = self, let butterfly = butterfly else { return }
            self.moveToNewRandomPoint(butterfly, anchor: anchor, radius: radius)
        }
    }
    
    private func moveToNewRandomPoint(_ butterfly: Entity, anchor: AnchorEntity, radius: Float) {
        let point = randomPointInCircle(radius: radius)
        let targetPosition = SIMD3<Float>(point.x, 0.35, point.y)

        let currentPosition = butterfly.position
        let direction = normalize(targetPosition - currentPosition)
        let targetRotation = simd_quatf(from: [0, 0, 1], to: direction)

        var targetTransform = butterfly.transform
        targetTransform.translation = targetPosition
        targetTransform.rotation = targetRotation

        butterfly.move(to: targetTransform, relativeTo: anchor, duration: 3.5, timingFunction: .easeInOut)
    }
    
    private func stopWandering() {
        wanderTimer?.invalidate()
        wanderTimer = nil
        
        if let active = self.activeButterfly {
            var targetTransform = Transform.identity
            targetTransform.translation = [0, 0.05, 0]
            targetTransform.scale = active.scale
            
            active.move(to: targetTransform, relativeTo: active.parent, duration: 1.5, timingFunction: .easeInOut)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self, weak active] in
                guard let self = self, let active = active else { return }
                if !self.isNear {
                    self.stopAllAnimationsRecursive(active)
                }
            }
        }
    }
    
    private func setFlowerHabitat(around anchor: AnchorEntity, radius: Float, count: Int, scale: Float) {
        guard let template = flowerHabitatTemplate else { return }

        for flower in scatteredFlowers {
            flower.scale = SIMD3<Float>(repeating: scale)
        }

        if scatteredFlowers.count < count {
            let needed = count - scatteredFlowers.count
            for _ in 0..<needed {
                let point = randomPointInCircle(radius: radius)
                let flower = template.clone(recursive: true)
                flower.scale = SIMD3<Float>(repeating: scale)
                flower.position = [point.x, 0, point.y]
                flower.orientation = simd_quatf(angle: Float.random(in: 0..<(2 * Float.pi)), axis: [0, 1, 0])
                anchor.addChild(flower)
                scatteredFlowers.append(flower)
            }
        } else if scatteredFlowers.count > count {
            let excess = scatteredFlowers.count - count
            let toRemove = Array(scatteredFlowers.suffix(excess))
            for flower in toRemove { flower.removeFromParent() }
            scatteredFlowers.removeLast(excess)
        }
    }
    
    private func randomPointInCircle(radius: Float) -> SIMD2<Float> {
        let angle = Float.random(in: 0..<(2 * Float.pi))
        let r = radius * sqrt(Float.random(in: 0...1))
        let x = cos(angle) * r
        let z = sin(angle) * r
        return SIMD2<Float>(x, z)
    }
    
    private func setEntityColor(_ entity: Entity, color: UIColor) {
        if var modelComponent = entity.components[ModelComponent.self] {
            let material = SimpleMaterial(color: color, roughness: 0.4, isMetallic: false)
            modelComponent.materials = modelComponent.materials.map { _ in material }
            entity.components.set(modelComponent)
        }
        for child in entity.children {
            setEntityColor(child, color: color)
        }
    }
    
    private func stopAllAnimationsRecursive(_ entity: Entity) {
        entity.stopAllAnimations()
        for child in entity.children {
            stopAllAnimationsRecursive(child)
        }
    }

    private func playAllAnimationsRecursive(_ entity: Entity) {
        for animation in entity.availableAnimations {
            entity.playAnimation(animation.repeat())
        }
        for child in entity.children {
            playAllAnimationsRecursive(child)
        }
    }
    
    func spawnAnimal(name animalName: String, on pAnchor: AnchorEntity) {
        guard let loadedAnimal = try? Entity.load(named: animalName) else {
            return
        }

        let targetScale: Float = 0.3
        loadedAnimal.scale = [0, 0, 0]
        loadedAnimal.generateCollisionShapes(recursive: true)
        loadedAnimal.components.set(InputTargetComponent())
        
        pAnchor.addChild(loadedAnimal)
        self.animalEntity = loadedAnimal
        
        if let animation = loadedAnimal.availableAnimations.first {
            loadedAnimal.playAnimation(animation.repeat())
        }
        
        if let cam = cameraAnchor {
            var camPosInAnchorSpace = cam.position(relativeTo: pAnchor)
            camPosInAnchorSpace.y = 0
            loadedAnimal.look(at: camPosInAnchorSpace, from: [0, 0, 0], relativeTo: pAnchor)
        }
        self.baseRotation = loadedAnimal.orientation
        
        isSpawningAnimal = false
        
        var animTimer: Float = 0.0
        let animDuration: Float = 0.8
        
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            animTimer += 0.02
            if animTimer >= animDuration {
                timer.invalidate()
                loadedAnimal.scale = SIMD3<Float>(repeating: targetScale)
                
                DispatchQueue.main.async {
                    self.currentAnimalName = animalName
                    self.isSpawningAnimal = false
                }
            } else {
                let progress = animTimer / animDuration
                let bounceScale = Float(sin(progress * .pi / 2)) * targetScale
                loadedAnimal.scale = [bounceScale, bounceScale, bounceScale]
            }
        }
    }
    
    deinit {
        wanderTimer?.invalidate()
    }
}

extension MeshResource {
    static func generateRing(innerRadius: Float, outerRadius: Float, segments: Int = 64) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []

        for i in 0...segments {
            let angle = (Float(i) / Float(segments)) * 2 * Float.pi
            let cosA = cos(angle)
            let sinA = sin(angle)

            positions.append(SIMD3<Float>(cosA * outerRadius, 0, sinA * outerRadius))
            normals.append(SIMD3<Float>(0, 1, 0))
            uvs.append(SIMD2<Float>(Float(i) / Float(segments), 1))

            positions.append(SIMD3<Float>(cosA * innerRadius, 0, sinA * innerRadius))
            normals.append(SIMD3<Float>(0, 1, 0))
            uvs.append(SIMD2<Float>(Float(i) / Float(segments), 0))
        }

        for i in 0..<segments {
            let outerCurrent = UInt32(i * 2)
            let innerCurrent = UInt32(i * 2 + 1)
            let outerNext = UInt32((i + 1) * 2)
            let innerNext = UInt32((i + 1) * 2 + 1)

            indices.append(contentsOf: [outerCurrent, innerCurrent, outerNext])
            indices.append(contentsOf: [innerCurrent, innerNext, outerNext])
        }

        var descriptor = MeshDescriptor(name: "ring")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        descriptor.primitives = .triangles(indices)

        return try! MeshResource.generate(from: [descriptor])
    }
    
    static func generateCircle(radius: Float, segments: Int = 64) -> MeshResource {
        var positions: [SIMD3<Float>] = [SIMD3<Float>(0, 0, 0)]
        var normals: [SIMD3<Float>] = [SIMD3<Float>(0, 1, 0)]
        var uvs: [SIMD2<Float>] = [SIMD2<Float>(0.5, 0.5)]
        var indices: [UInt32] = []

        for i in 0...segments {
            let angle = (Float(i) / Float(segments)) * 2 * Float.pi
            let x = cos(angle) * radius
            let z = sin(angle) * radius

            positions.append(SIMD3<Float>(x, 0, z))
            normals.append(SIMD3<Float>(0, 1, 0))
            uvs.append(SIMD2<Float>(cos(angle) * 0.5 + 0.5, sin(angle) * 0.5 + 0.5))

            if i < segments {
                indices.append(0)
                indices.append(UInt32(i + 1))
                indices.append(UInt32(i + 2))
            }
        }

        var descriptor = MeshDescriptor(name: "circle")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        descriptor.primitives = .triangles(indices)

        return try! MeshResource.generate(from: [descriptor])
    }
}
