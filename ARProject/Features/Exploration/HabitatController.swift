import RealityKit
import Foundation
import UIKit

class HabitatController {
    var circleEntities: [ModelEntity] = []
    var lineEntities: [ModelEntity] = []
    var auraPhase: Float = 0
    
    func setupHabitats(spots: [ARSpot], planeAnchor: Entity) {
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
    }
    
    func updateAura() {
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
    
    func animateCircleScale(for spot: ARSpot, to targetScale: Float) {
        guard let circle = spot.circleEntity else { return }
        var targetTransform = circle.transform
        targetTransform.scale = SIMD3<Float>(targetScale, 1.0, targetScale)
        circle.move(to: targetTransform, relativeTo: circle.parent, duration: 0.5, timingFunction: .easeInOut)
    }
    
    func setFlowerHabitat(at spot: ARSpot, count: Int, scale: Float, scatteringRadius: Float, template: Entity?, anchor: Entity) {
        guard let template = template else { return }

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
    
    func setEntityColor(_ entity: Entity, color: UIColor) {
        if var modelComponent = entity.components[ModelComponent.self] {
            let material = SimpleMaterial(color: color, roughness: 0.4, isMetallic: false)
            modelComponent.materials = modelComponent.materials.map { _ in material }
            entity.components.set(modelComponent)
        }
        for child in entity.children {
            setEntityColor(child, color: color)
        }
    }
}
