import RealityKit
import Foundation
import UIKit

class HabitatController {
    var circleEntities: [ModelEntity] = []
    var lineEntities: [ModelEntity] = []
    var auraPhase: Float = 0
    
    func setupHabitats(spots: [ARSpot], planeAnchor: Entity) {
        let circleMesh = MeshResource.generateCircle(radius: 1.5)
        var brownMaterial = PhysicallyBasedMaterial()
        brownMaterial.baseColor = .init(tint: .init(red: 0.42, green: 0.26, blue: 0.14, alpha: 1.0))
        brownMaterial.emissiveColor = .init(color: .init(red: 0.42, green: 0.26, blue: 0.14, alpha: 1.0))
        brownMaterial.emissiveIntensity = 2.0
        brownMaterial.roughness = .init(floatLiteral: 0.1)
        brownMaterial.metallic = .init(floatLiteral: 0.0)
        brownMaterial.faceCulling = .none
        brownMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.85))
        
        for spot in spots {
            let circle = ModelEntity(mesh: circleMesh, materials: [brownMaterial])
            circle.position = [spot.center.x, 0.02, spot.center.z]
            circle.scale = [0.25, 1.0, 0.25]
            planeAnchor.addChild(circle)
            spot.circleEntity = circle
            self.circleEntities.append(circle)
        }
        
        let xLineMesh = MeshResource.generateBox(width: 1.2, height: 0.002, depth: 0.005)
        let zLineMesh = MeshResource.generateBox(width: 0.005, height: 0.002, depth: 1.2)
        
        let lines = [
            ModelEntity(mesh: xLineMesh, materials: [brownMaterial]),
            ModelEntity(mesh: zLineMesh, materials: [brownMaterial]),
            ModelEntity(mesh: xLineMesh, materials: [brownMaterial]),
            ModelEntity(mesh: zLineMesh, materials: [brownMaterial])
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
        mat.baseColor = .init(tint: .init(red: 0.42, green: 0.26, blue: 0.14, alpha: 1.0))
        mat.emissiveColor = .init(color: .init(red: 0.42, green: 0.26, blue: 0.14, alpha: 1.0))
        mat.emissiveIntensity = 1.0 + pulse * 2.0
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
    
    func setReflective(_ entity: Entity) {
        applyReflectiveRecursive(entity)
    }

    private func applyReflectiveRecursive(_ entity: Entity) {
        if var modelComponent = entity.components[ModelComponent.self] {
            modelComponent.materials = modelComponent.materials.map { _ in
                var reflectiveMaterial = PhysicallyBasedMaterial()
                reflectiveMaterial.metallic = .init(floatLiteral: 1.0)
                reflectiveMaterial.roughness = .init(floatLiteral: 0.0)
                reflectiveMaterial.baseColor = .init(tint: .white)
                return reflectiveMaterial
            }
            entity.components[ModelComponent.self] = modelComponent
        }
        
        for child in entity.children {
            applyReflectiveRecursive(child)
        }
    }
}
