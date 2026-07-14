//
//  ARManager.swift
//  ARProject
//
//  Created by Ferdiansyah Annora on 14/07/26.
//

import SwiftUI
import RealityKit
import Combine

class ARManager: ObservableObject{
    @Published var currentAnimalName: String = ""
    var animalEntity: Entity?
    var cameraAnchor: AnchorEntity?
    var baseRotation: simd_quatf = .init(angle: 0, axis: [0, 1, 0])
    private var isSpawningAnimal = false
    
    private func spawnAnimal(name animalName: String, on pAnchor: AnchorEntity) {
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
}
