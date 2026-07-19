//
//  VirtualObjectARView.swift
//  ARProject
//
//  Created by Nadia Putri Natali Lubis on 14/07/26.
//
//  A custom `ARSCNView` subclass. This is where the actual spawning logic
//  for the animal and food objects lives, plus a couple of small ARSCNView
//  convenience helpers (raycasting, screen-center point).
//

import Foundation
import ARKit

class VirtualObjectARView: ARSCNView {
    // MARK: Spawning the Animal

    /// Every VirtualObject we've placed in the scene, whether it's the animal or a piece of food. `renderer(_:didUpdate:for:)` in ViewController+ARSCNViewDelegate.swift searches this array every frame to match an updated ARAnchor back to its SceneKit node.
    var allSpawnedObjects: [VirtualObject] = []

    // MARK: Anchor binding

    /// Registers (or re-registers) an ARAnchor for a VirtualObject at its CURRENT world position. Order matters here: the object's `simdWorldTransform` must already be set to where you want it *before* calling this, since the anchor is created from that transform. If the object already had an anchor, the old one is removed first so you don't end up with two anchors tracking the same object.
    func addOrUpdateAnchor(for object: VirtualObject) {
        if let anchor = object.anchor {
            session.remove(anchor: anchor)
        }
        let newAnchor = ARAnchor(transform: object.simdWorldTransform)
        object.anchor = newAnchor
        session.add(anchor: newAnchor)
    }

    /// Spawns a single dummy animal object at the specified raycast result location.
    ///
    /// Order of operations here is the key pattern you settled on after debugging the drift issue: attach the node to `scene.rootNode` FIRST (so it renders immediately), THEN register the ARAnchor. This is the opposite of waiting for ARKit's `didAdd` delegate callback, which was the source of the earlier pending-object bugs.
    
    func spawnAnimal(at result: ARRaycastResult) {
        if scene.rootNode.childNode(withName: "animal", recursively: true) != nil {
            print("An animal already exists in the scene!")
            return
        }
        
        let dummyAnimal = VirtualObject(dummyShape: .animalBox, color: .systemBlue, name: "animal")
        dummyAnimal.simdWorldTransform = result.worldTransform

        self.scene.rootNode.addChildNode(dummyAnimal)
        self.addOrUpdateAnchor(for: dummyAnimal)
        allSpawnedObjects.append(dummyAnimal)
    }

    // MARK: - Spawning Food Around the Animal

    /// Spawns 3 food models scattered evenly around the existing animal node.
    ///
    /// Uses polar coordinates (an angle + a radius) rather than independent random X/Z offsets — picking a random angle around a full circle and a random radius gives an even scatter around the animal. (Picking random X and Z independently instead tends to cluster points near the corners/center depending on the shape of the sampling area — polar sampling around a circle avoids that.)
    func spawnFoodAroundAnimal() {
        // Search the scene hierarchy to find your existing animal node
        guard let animalNode = self.scene.rootNode.childNode(withName: "animal", recursively: true) else {
            print("Error: Could not find the animal in the scene!")
            return
        }

        // Get the animal's current world position matrix
        let animalTransform = animalNode.simdWorldTransform

        for foodKind in VirtualObject.FoodKind.allCases {
            let foodObject = VirtualObject(foodKind: foodKind)

            let angle = Float.random(in: 0..<(2 * .pi))
            let radius = Float.random(in: 0.3...0.6)

            // Copy the animal's matrix and apply a polar offset to X/Z.
            var foodTransform = animalTransform
            foodTransform.columns.3.x += radius * cos(angle)
            foodTransform.columns.3.z += radius * sin(angle)
            foodTransform.columns.3.y = animalTransform.columns.3.y + 0.02

            foodObject.simdWorldTransform = foodTransform

            self.scene.rootNode.addChildNode(foodObject)
            self.addOrUpdateAnchor(for: foodObject)
            allSpawnedObjects.append(foodObject)
        }
    }
}

extension ARSCNView {
    /// Type conversion wrapper for original `unprojectPoint(_:)` method.
    /// Used in contexts where sticking to SIMD3<Float> type is helpful.
    func unprojectPoint(_ point: SIMD3<Float>) -> SIMD3<Float> {
        return SIMD3<Float>(unprojectPoint(SCNVector3(point)))
    }

    func castRay(for query: ARRaycastQuery) -> [ARRaycastResult] {
        return session.raycast(query)
    }

    /// Builds a raycast query from the center of the screen, first trying against actually-detected plane geometry (more accurate), falling back to ARKit's estimated-plane guess if no real plane has been found yet at that point (e.g. right after launch, before ARKit has scanned enough of the floor).
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
