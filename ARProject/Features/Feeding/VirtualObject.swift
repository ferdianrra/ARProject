//
//  VirtualObject.swift
//  ARProject
//
//  Created by Nadia Putri Natali Lubis on 14/07/26.
//
//  A `SCNReferenceNode` subclass for virtual objects placed into the AR scene.
//  Originally from Apple's ARKitInteraction sample (which loads real .scn
//  models the user can drag/rotate/reposition). This project currently only
//  uses the `dummyShape` initializer to create simple colored primitives
//  (a box for the animal, spheres for food), so several of the
//  drag/reposition-related properties below aren't exercised yet — see the
//  TAGs for details.
//

import Foundation
import SceneKit
import ARKit

class VirtualObject: SCNReferenceNode {

    /// The object's corresponding ARAnchor — this is how the object's world
    /// position gets kept in sync (see `addOrUpdateAnchor` and the
    /// `didUpdate` delegate callback).
    var anchor: ARAnchor?

    private var customModelName: String?

    /// The model name derived from the `referenceURL`, or the custom name
    /// passed into the `dummyShape` initializer (used to identify "animal"
    /// vs "food" nodes elsewhere via `childNode(withName:)`).
    var modelName: String {
        if let customName = customModelName {
            return customName
        }
        return referenceURL.lastPathComponent.replacingOccurrences(of: ".scn", with: "")
    }


    // MARK: - Initializer for Dummy Objects
    //
    // This is the initializer actually used throughout the project (see
    // VirtualObjectARView.spawnAnimal / spawnFoodAroundAnimal). It builds a
    // simple colored SceneKit primitive instead of loading a real .scn model,
    // which is why it starts from an `SCNReferenceNode` pointed at the
    // Models.scnassets bundle, then immediately `unload()`s the reference
    // content and swaps in a plain geometry node instead. This keeps the same
    // VirtualObject/anchor-tracking machinery working while you're still
    // using placeholder shapes.
    init(dummyShape: GeometryType, color: UIColor, name: String) {
        let bundleURL = Bundle.main.url(forResource: "Models.scnassets", withExtension: nil) ?? URL(fileURLWithPath: "")

        super.init(url: bundleURL)!

        self.unload()

        self.customModelName = name

        let geometry: SCNGeometry

        switch dummyShape {
        case .foodSphere:
            geometry = SCNSphere(radius: 0.05)
        case .animalBox:
            geometry = SCNBox(width: 0.4, height: 0.4, length: 0.4, chamferRadius: 0.05)
        }

        let material = SCNMaterial()
        material.diffuse.contents = color
        material.lightingModel = .physicallyBased
        geometry.materials = [material]

        let wrapperNode = SCNNode(geometry: geometry)
        wrapperNode.name = name

        // Shifts the pivot so the shape sits "on top of" its origin rather
        // than centered around it — useful once these are placed on a floor
        // plane, so the object rests on the surface instead of being half
        // sunk into it.
        let (min, max) = geometry.boundingBox
        wrapperNode.pivot = SCNMatrix4MakeTranslation(0, (max.y - min.y)/2, 0)

        self.addChildNode(wrapperNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum GeometryType {
        case foodSphere
        case animalBox
    }
}
