import RealityKit
import UIKit
import Foundation

class FactController {
    func toggleFacts(show: Bool, animal: Entity?) {
        guard let animal = animal else { return }
        
        if show {
            let facts = [
                ("The African Giant Swallowtail (Papilio antimachus)", SIMD3<Float>(0, 0.35, 0), UIColor.purple),
                ("Location: West & Central Africa", SIMD3<Float>(-0.25, 0.2, 0), UIColor.systemBlue),
                ("Endangered Status: Data Deficient (DD)", SIMD3<Float>(0.25, 0.2, 0), UIColor.systemOrange),
                ("Size: Wingspan 18-23 cm", SIMD3<Float>(0, 0.2, 0.25), UIColor.systemGreen)
            ]
            
            // Calculate inverse scale to counter the butterfly's tiny scale (e.g. 0.001)
            let inverseScale = 1.0 / animal.scale.y
            
            for (index, fact) in facts.enumerated() {
                let textEntity = createTextEntity(text: fact.0, color: fact.2)
                textEntity.name = "factTag_\(index)"
                // Multiply position by inverseScale so it hovers at the correct world height
                textEntity.position = fact.1 * inverseScale
                // Scale it up by inverseScale so the sticky note is readable (22cm world size)
                textEntity.scale = SIMD3<Float>(repeating: inverseScale)
                animal.addChild(textEntity)
            }
        } else {
            let children = animal.children.filter { $0.name.hasPrefix("factTag_") }
            for child in children {
                child.removeFromParent()
            }
        }
    }
    
    private func createTextEntity(text: String, color: UIColor) -> Entity {
        let noteSize: Float = 0.22
        
        // 1. Create the square post-it note paper
        let paperMesh = MeshResource.generatePlane(width: noteSize, height: noteSize, cornerRadius: 0.01)
        let paperMaterial = SimpleMaterial(color: color, roughness: 0.8, isMetallic: false)
        let paperEntity = ModelEntity(mesh: paperMesh, materials: [paperMaterial])
        
        // 2. Create the text that wraps inside the square
        let textMargin: Float = 0.02
        let textWidth = noteSize - textMargin * 2
        // Container frame is centered
        let textRect = CGRect(x: CGFloat(-textWidth / 2), y: CGFloat(-textWidth / 2), width: CGFloat(textWidth), height: CGFloat(textWidth))
        
        let textMesh = MeshResource.generateText(text, 
                                                 extrusionDepth: 0.001, 
                                                 font: .boldSystemFont(ofSize: 0.022), 
                                                 containerFrame: textRect, 
                                                 alignment: .center, 
                                                 lineBreakMode: .byWordWrapping)
        
        let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        
        // Put text slightly in front of the paper
        textEntity.position = [0, 0, 0.002]
        
        let wrapper = Entity()
        wrapper.addChild(paperEntity)
        wrapper.addChild(textEntity)
        return wrapper
    }
    
    func updateBillboards(cameraAnchor: AnchorEntity, animal: Entity?) {
        guard let animal = animal else { return }
        
        let billboards = animal.children.filter { $0.name.hasPrefix("factTag_") || $0.name == "phaseText" }
        for billboard in billboards {
            billboard.look(at: cameraAnchor.position(relativeTo: animal), from: billboard.position(relativeTo: animal), relativeTo: animal)
            billboard.transform.rotation *= simd_quatf(angle: .pi, axis: [0, 1, 0])
        }
    }
}
