//
//  VirtualObjectARView.swift
//  ARProject
//
//  Created by Nadia Putri Natali Lubis on 14/07/26.
//

import Foundation

/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A custom `ARSCNView` configured for the requirements of this project.
*/

import Foundation
import ARKit

class VirtualObjectARView: ARSCNView {

    // MARK: Position Testing
    
    /// Hit tests against the `sceneView` to find an object at the provided point.
//    func virtualObject(at point: CGPoint) -> VirtualObject? {
//        let hitTestOptions: [SCNHitTestOption: Any] = [.boundingBoxOnly: true]
//        let hitTestResults = hitTest(point, options: hitTestOptions)
//        
//        return hitTestResults.lazy.compactMap { result in
//            return VirtualObject.existingObjectContainingNode(result.node)
//        }.first
//    }
    
    // - MARK: Object anchors
    func addOrUpdateAnchor(for object: VirtualObject) {
        // If the anchor is not nil, remove it from the session.
        if let anchor = object.anchor {
            session.remove(anchor: anchor)
        }
        
        // Create a new anchor with the object's current transform and add it to the session
        let newAnchor = ARAnchor(transform: object.simdWorldTransform)
        object.anchor = newAnchor
        session.add(anchor: newAnchor)
    }
    
    func spawnThreeRandomFoods(at baseResult: ARRaycastResult) {
        let baseTransform = baseResult.worldTransform
        
        for i in 1...3 {
            let dummyFood = VirtualObject(dummyShape: .foodSphere, color: .orange, name: "food_\(i)")
            
            let randomX = Float.random(in: -0.2...0.2)
            let randomZ = Float.random(in: -0.2...0.2)
            
            var randomTransform = baseTransform
            randomTransform.columns.3.x += randomX
            randomTransform.columns.3.z += randomZ
            
            randomTransform.columns.3.y += 0.02
            
            dummyFood.simdWorldTransform = randomTransform
            
            self.scene.rootNode.addChildNode(dummyFood)
            self.addOrUpdateAnchor(for: dummyFood)
        }
    }
    
    // - MARK: Spawning the Animal
    
    // VirtualObjectARView.swift atau ViewController, simpen mapping ini
    var pendingVirtualObjects: [UUID: VirtualObject] = [:]

    /// Spawns a single dummy animal object at the specified raycast result location.
    func spawnAnimal(at result: ARRaycastResult) {
        // 1. Check if an animal already exists so we don't spawn multiple animals
        if self.scene.rootNode.childNode(withName: "animal", recursively: true) != nil {
            print("An animal already exists in the scene!")
            return
        }
        
        // 2. Create the animal using the custom dummy initializer (.animalBox is a 40cm blue box)
        let dummyAnimal = VirtualObject(dummyShape: .animalBox, color: .systemBlue, name: "animal")
        
        let anchor = ARAnchor(transform: result.worldTransform)
        
        dummyAnimal.anchor = anchor
        pendingVirtualObjects[anchor.identifier] = dummyAnimal
        session.add(anchor: anchor)
    }
    
    
    // - MARK: Spawning Food Around the Animal

    /// Spawns 3 random food dummy objects scattered around the existing animal node.
    func spawnFoodAroundAnimal() {
        // 1. Search the scene hierarchy to find your existing animal node
        guard let animalNode = self.scene.rootNode.childNode(withName: "animal", recursively: true) else {
            print("Error: Could not find the animal in the scene!")
            return
        }
        
        // 2. Get the animal's current world position matrix
        let animalTransform = animalNode.simdWorldTransform
        
        for _ in 1...3 {
            // 3. Create a unique food dummy object
            let dummyFood = VirtualObject(dummyShape: .foodSphere, color: .orange, name: "food")
            
            let angle = Float.random(in: 0..<(2 * .pi))
            let radius = Float.random(in: 1...1.5)
            
            // 5. Copy the animal's matrix and apply the offsets to X and Z
            var foodTransform = animalTransform
            foodTransform.columns.3.x += radius * cos(angle)
            foodTransform.columns.3.z += radius * sin(angle)
            foodTransform.columns.3.y = animalTransform.columns.3.y + 0.02

            let anchor = ARAnchor(transform: foodTransform)
            
            dummyFood.anchor = anchor
            pendingVirtualObjects[anchor.identifier] = dummyFood
            session.add(anchor: anchor)
        }
    }
}

extension ARSCNView {
    /**
     Type conversion wrapper for original `unprojectPoint(_:)` method.
     Used in contexts where sticking to SIMD3<Float> type is helpful.
     */
    func unprojectPoint(_ point: SIMD3<Float>) -> SIMD3<Float> {
        return SIMD3<Float>(unprojectPoint(SCNVector3(point)))
    }
    
    func castRay(for query: ARRaycastQuery) -> [ARRaycastResult] {
        return session.raycast(query)
    }

    func getRaycastQuery(for alignment: ARRaycastQuery.TargetAlignment = .any) -> ARRaycastQuery? {
        if let query = raycastQuery(from: screenCenter, allowing: .existingPlaneGeometry, alignment: alignment) {
                return query
            }
        
        return raycastQuery(from: screenCenter, allowing: .estimatedPlane, alignment: alignment)
    }
    
    var screenCenter: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
}
