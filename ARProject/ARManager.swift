import SwiftUI
import RealityKit
import ARKit
import Combine

class ARSpot {
    let id: Int
    let center: SIMD3<Float>
    var hasVisited: Bool = false
    var isNear: Bool = false
    
    var blackButterfly: Entity?
    var activeButterfly: Entity?
    var wanderTimer: Timer?
    var scatteredFlowers: [Entity] = []
    
    var circleEntity: ModelEntity?
    
    init(id: Int, center: SIMD3<Float>) {
        self.id = id
        self.center = center
    }
}

class ARManager: ObservableObject {
    @Published var distanceText: String = "Mencari objek..."
    @Published var currentAnimalName: String = ""
    
    var cameraAnchor: AnchorEntity?
    var cubeModel: Entity?
    var baseRotation: simd_quatf = .init(angle: 0, axis: [0, 1, 0])
    var animalEntity: Entity?
    
    private var isSpawningAnimal = false
    
    private var coloredButterflyTemplate: Entity?
    private var flowerHabitatTemplate: Entity?
    
    private var anchorRef: AnchorEntity?
    private var circleEntities: [ModelEntity] = []
    private var lineEntities: [ModelEntity] = []
    private var auraTimer: Timer?
    private var auraPhase: Float = 0
    
    private var spots: [ARSpot] = [
        ARSpot(id: 0, center: [-0.6, 0.05, -0.6]),
        ARSpot(id: 1, center: [ 0.6, 0.05, -0.6]),
        ARSpot(id: 2, center: [-0.6, 0.05,  0.6]),
        ARSpot(id: 3, center: [ 0.6, 0.05,  0.6])
    ]
    
    func setup(cameraAnchor: AnchorEntity, planeAnchor: AnchorEntity) {
        self.cameraAnchor = cameraAnchor
        self.anchorRef = planeAnchor
        
        let circleMesh = MeshResource.generateCircle(radius: 1.5)
        var blueMaterial = PhysicallyBasedMaterial()
        blueMaterial.baseColor = .init(tint: .black)
        blueMaterial.emissiveColor = .init(color: .init(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0))
        blueMaterial.emissiveIntensity = 3.0
        blueMaterial.roughness = .init(floatLiteral: 0.1)
        blueMaterial.metallic = .init(floatLiteral: 0.0)
        blueMaterial.faceCulling = .none
        blueMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.85))
        
        for spot in spots {
            let circle = ModelEntity(mesh: circleMesh, materials: [blueMaterial])
            circle.position = [spot.center.x, 0.02, spot.center.z]
            circle.scale = [0.25, 1.0, 0.25]
            planeAnchor.addChild(circle)
            spot.circleEntity = circle
            self.circleEntities.append(circle)
        }
        
        let xLineMesh = MeshResource.generateBox(width: 1.2, height: 0.002, depth: 0.005)
        let zLineMesh = MeshResource.generateBox(width: 0.005, height: 0.002, depth: 1.2)
        
        let lines = [
            ModelEntity(mesh: xLineMesh, materials: [blueMaterial]),
            ModelEntity(mesh: zLineMesh, materials: [blueMaterial]),
            ModelEntity(mesh: xLineMesh, materials: [blueMaterial]),
            ModelEntity(mesh: zLineMesh, materials: [blueMaterial])
        ]
        
        lines[0].position = [0, 0.02, -0.6]
        lines[1].position = [0.6, 0.02, 0]
        lines[2].position = [0, 0.02, 0.6]
        lines[3].position = [-0.6, 0.02, 0]
        
        for line in lines {
            planeAnchor.addChild(line)
            self.lineEntities.append(line)
        }
        
        auraTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.auraPhase += 0.05
            let pulse = (sin(self.auraPhase) + 1) / 2
            
            var mat = PhysicallyBasedMaterial()
            mat.baseColor = .init(tint: .black)
            mat.emissiveColor = .init(color: .init(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0))
            mat.emissiveIntensity = 2.0 + pulse * 3.0
            mat.roughness = .init(floatLiteral: 0.1)
            mat.metallic = .init(floatLiteral: 0.0)
            mat.faceCulling = .none
            mat.blending = .transparent(opacity: .init(floatLiteral: 0.85))
            
            let allVisuals = self.circleEntities + self.lineEntities
            for visual in allVisuals {
                if visual.isEnabled {
                    visual.model?.materials = [mat]
                }
            }
        }
        
        Task {
            do {
                let template = try await Entity(named: "butterfly", in: nil)
                self.coloredButterflyTemplate = template.clone(recursive: true)
                
                for spot in spots {
                    let blackButterfly = template.clone(recursive: true)
                    self.setEntityColor(blackButterfly, color: .black)
                    self.stopAllAnimationsRecursive(blackButterfly)
                    blackButterfly.scale = SIMD3<Float>(repeating: 0.0008)
                    blackButterfly.position = spot.center
                    planeAnchor.addChild(blackButterfly)
                    spot.blackButterfly = blackButterfly
                }
            } catch {
                print("error load butterfly.usdz: \(error)")
            }
            
            do {
                let flowerTemplate = try await Entity(named: "flower_habitat", in: nil)
                self.flowerHabitatTemplate = flowerTemplate
                
                for spot in spots {
                    self.setFlowerHabitat(at: spot, count: 6, scale: 0.0005, scatteringRadius: 0.2)
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

        let cameraPosition = camAnchor.position(relativeTo: nil)
        let cameraFlat = SIMD2<Float>(cameraPosition.x, cameraPosition.z)
        
        var closestDistance = Float.infinity
        let activeSpot = spots.first(where: { $0.isNear })

        for spot in spots {
            let spotWorldPos = anchor.convert(position: spot.center, to: nil)
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
                        
                        self.animateCircleScale(for: spot, to: 1.0)
                        
                        if let existing = spot.activeButterfly {
                            existing.isEnabled = true
                            self.startWandering(existing, at: spot)
                        } else {
                            self.spawnButterfly(at: spot)
                        }
                        self.setFlowerHabitat(at: spot, count: 24, scale: 0.0012, scatteringRadius: 1.3)
                    }
                }
            } else {
                if spot.isNear {
                    spot.isNear = false
                    self.stopWandering(at: spot)
                    self.animateCircleScale(for: spot, to: 0.25)
                    self.setFlowerHabitat(at: spot, count: 6, scale: 0.0005, scatteringRadius: 0.2)
                }
            }
        }
        
        if let currentActive = spots.first(where: { $0.isNear }) {
            for line in lineEntities {
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
            for line in lineEntities {
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
    
    private func animateCircleScale(for spot: ARSpot, to targetScale: Float) {
        guard let circle = spot.circleEntity else { return }
        var targetTransform = circle.transform
        targetTransform.scale = SIMD3<Float>(targetScale, 1.0, targetScale)
        circle.move(to: targetTransform, relativeTo: circle.parent, duration: 0.5, timingFunction: .easeInOut)
    }
    
    private func spawnButterfly(at spot: ARSpot) {
        guard let template = coloredButterflyTemplate, let anchor = anchorRef else { return }
        let butterfly = template.clone(recursive: true)
        butterfly.scale = SIMD3<Float>(repeating: 0.001)
        let point = randomPointInCircle(radius: 1.3)
        butterfly.position = [spot.center.x + point.x, 0.35, spot.center.z + point.y]
        anchor.addChild(butterfly)
        playAllAnimationsRecursive(butterfly)
        spot.activeButterfly = butterfly
        startWandering(butterfly, at: spot)
    }
    
    private func startWandering(_ butterfly: Entity, at spot: ARSpot) {
        playAllAnimationsRecursive(butterfly)
        moveToNewRandomPoint(butterfly, at: spot)

        let interval: TimeInterval = 4.0
        spot.wanderTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self, weak butterfly] _ in
            guard let self = self, let butterfly = butterfly else { return }
            self.moveToNewRandomPoint(butterfly, at: spot)
        }
    }
    
    private func moveToNewRandomPoint(_ butterfly: Entity, at spot: ARSpot) {
        guard let anchor = anchorRef else { return }
        let point = randomPointInCircle(radius: 1.3)
        let targetPosition = SIMD3<Float>(spot.center.x + point.x, 0.35, spot.center.z + point.y)

        let currentPosition = butterfly.position
        let direction = normalize(targetPosition - currentPosition)
        let targetRotation = simd_quatf(from: [0, 0, 1], to: direction)

        var targetTransform = butterfly.transform
        targetTransform.translation = targetPosition
        targetTransform.rotation = targetRotation

        butterfly.move(to: targetTransform, relativeTo: anchor, duration: 3.5, timingFunction: .easeInOut)
    }
    
    private func stopWandering(at spot: ARSpot) {
        spot.wanderTimer?.invalidate()
        spot.wanderTimer = nil
        
        if let active = spot.activeButterfly {
            var targetTransform = Transform.identity
            targetTransform.translation = spot.center
            targetTransform.scale = active.scale
            
            active.move(to: targetTransform, relativeTo: active.parent, duration: 1.5, timingFunction: .easeInOut)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self, weak active] in
                guard let self = self, let active = active else { return }
                if !spot.isNear {
                    self.stopAllAnimationsRecursive(active)
                }
            }
        }
    }
    
    private func setFlowerHabitat(at spot: ARSpot, count: Int, scale: Float, scatteringRadius: Float) {
        guard let template = flowerHabitatTemplate, let anchor = anchorRef else { return }

        for flower in spot.scatteredFlowers {
            flower.scale = SIMD3<Float>(repeating: scale)
            let point = randomPointInCircle(radius: scatteringRadius)
            flower.position = [spot.center.x + point.x, 0, spot.center.z + point.y]
        }

        if spot.scatteredFlowers.count < count {
            let needed = count - spot.scatteredFlowers.count
            for _ in 0..<needed {
                let point = randomPointInCircle(radius: scatteringRadius)
                let flower = template.clone(recursive: true)
                flower.scale = SIMD3<Float>(repeating: scale)
                flower.position = [spot.center.x + point.x, 0, spot.center.z + point.y]
                flower.orientation = simd_quatf(angle: Float.random(in: 0..<(2 * Float.pi)), axis: [0, 1, 0])
                anchor.addChild(flower)
                spot.scatteredFlowers.append(flower)
            }
        } else if spot.scatteredFlowers.count > count {
            let excess = spot.scatteredFlowers.count - count
            let toRemove = Array(spot.scatteredFlowers.suffix(excess))
            for flower in toRemove { flower.removeFromParent() }
            spot.scatteredFlowers.removeLast(excess)
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

        let targetScale: Float = 0.2
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
        for spot in spots {
            spot.wanderTimer?.invalidate()
        }
        auraTimer?.invalidate()
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
