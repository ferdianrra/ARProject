//
//  VirtualObject.swift
//  ARProject
//
//  Created by Nadia Putri Natali Lubis on 14/07/26.
//

import Foundation

/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A `SCNReferenceNode` subclass for virtual objects placed into the AR scene.
*/

import Foundation
import SceneKit
import ARKit

class VirtualObject: SCNReferenceNode {
    
    /// The object's corresponding ARAnchor.
    var anchor: ARAnchor?

    /// The raycast query used when placing this object.
    var raycastQuery: ARRaycastQuery?
    
    /// The associated tracked raycast used to place this object.
    var raycast: ARTrackedRaycast?
    
    /// The most recent raycast result used for determining the initial location
    /// of the object after placement.
    var mostRecentInitialPlacementResult: ARRaycastResult?
    
    /// Flag that indicates the associated anchor should be updated
    /// at the end of a pan gesture or when the object is repositioned.
    var shouldUpdateAnchor = false
    
    private var customModelName: String?
    
    /// The model name derived from the `referenceURL`.
    var modelName: String {
        if let customName = customModelName {
            return customName
        }
        return referenceURL.lastPathComponent.replacingOccurrences(of: ".scn", with: "")
    }
    
    /// The alignments that are allowed for a virtual object.
    var allowedAlignment: ARRaycastQuery.TargetAlignment {
        return .horizontal
    }
    
    /// Rotates the first child node of a virtual object.
    /// - Note: For correct rotation on horizontal and vertical surfaces, rotate around
    /// local y rather than world y.
    var objectRotation: Float {
        get {
            return childNodes.first!.eulerAngles.y
        }
        set (newValue) {
            childNodes.first!.eulerAngles.y = newValue
        }
    }
    
    // MARK: - New Initializer for Dummy Objects
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
    
    
    /// Stops tracking the object's position and orientation.
    func stopTrackedRaycast() {
        raycast?.stopTracking()
        raycast = nil
    }
}

//extension VirtualObject {
//    // MARK: Static Properties and Methods
//    /// Loads all the model objects within `Models.scnassets`.
//    static let availableObjects: [VirtualObject] = {
//        let modelsURL = Bundle.main.url(forResource: "Models.scnassets", withExtension: nil)!
//
//        let fileEnumerator = FileManager().enumerator(at: modelsURL, includingPropertiesForKeys: [])!
//
//        return fileEnumerator.compactMap { element in
//            let url = element as! URL
//
//            guard url.pathExtension == "scn" && !url.path.contains("lighting") else { return nil }
//
//            return VirtualObject(url: url)
//        }
//    }()
//    
//    /// Returns a `VirtualObject` if one exists as an ancestor to the provided node.
//    static func existingObjectContainingNode(_ node: SCNNode) -> VirtualObject? {
//        if let virtualObjectRoot = node as? VirtualObject {
//            return virtualObjectRoot
//        }
//        
//        guard let parent = node.parent else { return nil }
//        
//        // Recurse up to check if the parent is a `VirtualObject`.
//        return existingObjectContainingNode(parent)
//    }
//}
