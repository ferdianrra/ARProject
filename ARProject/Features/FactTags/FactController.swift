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
    func toggleFacts(show: Bool, animal: Entity?, animalTypeName: String) {
        guard let animal = animal else { return }
        
        if show {
            let animalFacts = AnimalFactData.facts(for: animalTypeName)
            let positions: [SIMD3<Float>] = [
                SIMD3<Float>(0, 0.35, 0),
                SIMD3<Float>(-0.25, 0.2, 0),
                SIMD3<Float>(0.25, 0.2, 0),
                SIMD3<Float>(0, 0.2, 0.25)
            ]
            let colors: [UIColor] = [.purple, .systemBlue, .systemOrange, .systemGreen]
            
            let inverseScale = 1.0 / animal.scale.y
            
            for (index, fact) in animalFacts.enumerated() where index < positions.count {
                let cardEntity = createFactCard(fact: fact, color: colors[index])  
                cardEntity.name = "factTag_\(index)"
                cardEntity.position = positions[index] * inverseScale
                cardEntity.scale = SIMD3<Float>(repeating: inverseScale)
                animal.addChild(cardEntity)
            }
        } else {
            let children = animal.children.filter { $0.name.hasPrefix("factTag_") }
            for child in children {
                child.removeFromParent()
            }
        }
    }
    
    private func createFactCard(fact: ButterflyFact, color: UIColor) -> Entity {
        let noteSize: Float = 0.28
        
        let paperMesh = MeshResource.generatePlane(width: noteSize, height: noteSize, cornerRadius: 0.01)
        let paperMaterial = SimpleMaterial(color: color, roughness: 0.8, isMetallic: false)
        let paperEntity = ModelEntity(mesh: paperMesh, materials: [paperMaterial])
        
        let wrapper = Entity()
        wrapper.addChild(paperEntity)
        
        // COMMENTED OUT: SF Symbol icon on 3D AR card.
        // The active FunFact UI is the 2D ButterflyFactSheetView, not these 3D cards.
        // The emoji/SF Symbol is now displayed inside ButterflyFactSheetView using Image(systemName:).
        // 🔧 1. SF Symbol icon di bagian atas kartu
        // let iconSize: Float = 0.06
        // let symbolIcon = createSymbolBillboard(systemName: fact.emoji, size: iconSize, tint: .white)
        // symbolIcon.position = [0, noteSize * 0.28, 0.003]
        // wrapper.addChild(symbolIcon)
        
        // 🔧 2. Title text, di bawah icon
        let titleMargin: Float = 0.02
        let titleWidth = noteSize - titleMargin * 2
        let titleRect = CGRect(x: CGFloat(-titleWidth / 2), y: 0, width: CGFloat(titleWidth), height: CGFloat(0.06))
        let titleMesh = MeshResource.generateText(fact.title,
                                                  extrusionDepth: 0.001,
                                                  font: .boldSystemFont(ofSize: 0.026),
                                                  containerFrame: titleRect,
                                                  alignment: .center,
                                                  lineBreakMode: .byWordWrapping)
        let titleMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let titleEntity = ModelEntity(mesh: titleMesh, materials: [titleMaterial])
        titleEntity.position = [0, noteSize * 0.06, 0.002]
        wrapper.addChild(titleEntity)
        
        // 🔧 3. Body text, di bawah title
        let textMargin: Float = 0.02
        let textWidth = noteSize - textMargin * 2
        let textRect = CGRect(x: CGFloat(-textWidth / 2), y: CGFloat(-noteSize * 0.4), width: CGFloat(textWidth), height: CGFloat(noteSize * 0.4))
        let textMesh = MeshResource.generateText(fact.text,
                                                 extrusionDepth: 0.001,
                                                 font: .systemFont(ofSize: 0.018),
                                                 containerFrame: textRect,
                                                 alignment: .center,
                                                 lineBreakMode: .byWordWrapping)
        let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        textEntity.position = [0, 0, 0.002]
        wrapper.addChild(textEntity)
        
        return wrapper
    }
    
    private func createSymbolBillboard(systemName: String, size: Float = 0.25, tint: UIColor = .white) -> Entity {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256))
        let img = renderer.image { context in
            // SF Symbol Drawing
            let config = UIImage.SymbolConfiguration(weight: .bold)
            if let symbolImage = UIImage(systemName: systemName, withConfiguration: config)?
                .withTintColor(tint, renderingMode: .alwaysOriginal) {
                
                let imageSize = symbolImage.size
                let targetSize: CGFloat = 210
                let scale = min(targetSize / imageSize.width, targetSize / imageSize.height)
                let newWidth = imageSize.width * scale
                let newHeight = imageSize.height * scale
                
                let rect = CGRect(
                    x: (256 - newWidth) / 2,
                    y: (256 - newHeight) / 2,
                    width: newWidth,
                    height: newHeight
                )
                tint.set()
                symbolImage.draw(in: rect)
            }
            
            /* COMMENTED OUT: Emoji Drawing
            let font = UIFont.systemFont(ofSize: 140)
            let attrs: [NSAttributedString.Key: Any] = [.font: font]
            let string = systemName as NSString
            let stringSize = string.size(withAttributes: attrs)
            let rect = CGRect(
                x: (256 - stringSize.width) / 2,
                y: (256 - stringSize.height) / 2,
                width: stringSize.width,
                height: stringSize.height
            )
            string.draw(in: rect, withAttributes: attrs)
            */
        }
        
        guard let cgImage = img.cgImage,
              let texture = try? TextureResource.generate(from: cgImage, options: .init(semantic: .color)) else {
            let plane = MeshResource.generatePlane(width: size, height: size)
            return ModelEntity(mesh: plane, materials: [SimpleMaterial(color: .white, isMetallic: false)])
        }

        var material = UnlitMaterial()
        material.color = .init(tint: .white, texture: .init(texture))
        material.opacityThreshold = 0.1

        let mesh = MeshResource.generatePlane(width: size, height: size)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        return entity
    }
    
    func spawnSymbol(systemName: String, at spot: ARSpot, tint: UIColor = .white) { 
        guard let animal = spot.animalModel ?? spot.reflectiveAnimal else { return }
        
        let existing = animal.children.filter { $0.name.hasPrefix("decisionSymbol_") }
        for child in existing { child.removeFromParent() }
        
        let currentScale = animal.scale.y == 0 ? 0.001 : animal.scale.y
        let inverseScale = 1.0 / currentScale
        
        let symbolEntity = createSymbolBillboard(systemName: systemName, size: 0.35 * inverseScale, tint: tint)
        symbolEntity.name = "decisionSymbol_\(spot.id)"
        symbolEntity.position = SIMD3<Float>(0, 0.45, 0) * inverseScale
        animal.addChild(symbolEntity)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak symbolEntity] in
            symbolEntity?.removeFromParent()
        }
    }
    
    func updateBillboards(cameraAnchor: AnchorEntity, animal: Entity?) {
        guard let animal = animal, let parent = animal.parent else { return }
        
        let billboards = animal.children.filter { $0.name.hasPrefix("factTag_") || $0.name == "phaseText" || $0.name.hasPrefix("decisionSymbol_") }
        let camWorldPos = cameraAnchor.position(relativeTo: parent)
        let animalWorldPos = animal.position(relativeTo: parent)
        
        for billboard in billboards {
            let billboardWorldPos = animalWorldPos + (animal.orientation.act(billboard.position))
            let diff = camWorldPos - billboardWorldPos
            let yaw = atan2(diff.x, diff.z)
            billboard.orientation = animal.orientation.inverse * simd_quatf(angle: yaw + .pi, axis: [0, 1, 0])
        }
    }
}
