//
//  FactController.swift
//  ARProject
//
//  Created by Ferdiansyah Annora on 21/07/26.
//

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
    
    /// Generates a full-color 3D Unlit Plane with transparent background containing the native Apple Emoji.
    private func createEmojiBillboard(emoji: String, size: Float = 0.25) -> Entity {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256))
        let img = renderer.image { _ in
            let font = UIFont.systemFont(ofSize: 180)
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            let str = NSString(string: emoji)
            let textSize = str.size(withAttributes: attributes)
            let rect = CGRect(
                x: (256 - textSize.width) / 2,
                y: (256 - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            str.draw(in: rect, withAttributes: attributes)
        }

        guard let cgImage = img.cgImage,
              let texture = try? TextureResource.generate(from: cgImage, options: .init(semantic: .color)) else {
            let plane = MeshResource.generatePlane(width: size, height: size)
            return ModelEntity(mesh: plane, materials: [SimpleMaterial(color: .yellow, isMetallic: false)])
        }

        var material = UnlitMaterial()
        material.color = .init(tint: .white, texture: .init(texture))
        material.opacityThreshold = 0.1

        let mesh = MeshResource.generatePlane(width: size, height: size)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        return entity
    }

    func spawnEmoji(emoji: String, at spot: ARSpot) {
        guard let butterfly = spot.activeButterfly ?? spot.blackButterfly else { return }
        
        let existing = butterfly.children.filter { $0.name.hasPrefix("decisionEmoji_") }
        for child in existing { child.removeFromParent() }

        let currentScale = butterfly.scale.y == 0 ? 0.001 : butterfly.scale.y
        let inverseScale = 1.0 / currentScale
        
        // Size 0.35m scaled to inverse scale
        let emojiEntity = createEmojiBillboard(emoji: emoji, size: 0.35 * inverseScale)
        emojiEntity.name = "decisionEmoji_\(spot.id)"
        emojiEntity.position = SIMD3<Float>(0, 0.45, 0) * inverseScale
        butterfly.addChild(emojiEntity)

        // Auto remove emoji after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak emojiEntity] in
            emojiEntity?.removeFromParent()
        }
    }
    
    func updateBillboards(cameraAnchor: AnchorEntity, animal: Entity?) {
        guard let animal = animal else { return }
        
        let billboards = animal.children.filter { $0.name.hasPrefix("factTag_") || $0.name == "phaseText" || $0.name.hasPrefix("decisionEmoji_") }
        for billboard in billboards {
            billboard.look(at: cameraAnchor.position(relativeTo: animal), from: billboard.position(relativeTo: animal), relativeTo: animal)
            billboard.transform.rotation *= simd_quatf(angle: .pi, axis: [0, 1, 0])
        }
    }
}
