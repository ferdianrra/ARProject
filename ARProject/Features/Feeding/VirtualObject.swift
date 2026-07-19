//
//  VirtualObject.swift
//  ARProject
//
//  Created by Nadia Putri Natali Lubis on 14/07/26.
//
//  A `SCNReferenceNode` subclass for virtual objects placed into the AR scene.
//  Originally from Apple's ARKitInteraction sample (which loads real .scn
//  models the user can drag/rotate/reposition). This project currently uses
//  placeholder primitives for the animal and USDZ resources for food.
//

import Foundation
import SceneKit
import ARKit

class VirtualObject: SCNReferenceNode {

    /// The object's corresponding ARAnchor — this is how the object's world
    /// position gets kept in sync (see `addOrUpdateAnchor` and the
    /// `didUpdate` delegate callback).
    var anchor: ARAnchor?

    var foodKind: FoodKind?

    private var customModelName: String?

    /// The model name derived from the `referenceURL`, or the custom name
    /// passed into the custom initializers (used to identify "animal"
    /// vs "food" nodes elsewhere via `childNode(withName:)`).
    var modelName: String {
        if let customName = customModelName {
            return customName
        }
        return referenceURL.lastPathComponent.replacingOccurrences(of: ".scn", with: "")
    }

    // MARK: - Initializer for Dummy Objects

    init(dummyShape: GeometryType, color: UIColor, name: String) {
        let bundleURL = Bundle.main.url(forResource: "Models.scnassets", withExtension: nil) ?? URL(fileURLWithPath: "")

        super.init(url: bundleURL)!

        self.unload()
        self.customModelName = name
        self.name = name

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
        wrapperNode.pivot = SCNMatrix4MakeTranslation(0, (max.y - min.y) / 2, 0)

        self.addChildNode(wrapperNode)
    }

    // MARK: - Initializer for Food Models

    init(foodKind: FoodKind) {
        let bundleURL = Bundle.main.url(forResource: "Models.scnassets", withExtension: nil) ?? URL(fileURLWithPath: "")

        super.init(url: bundleURL)!

        self.unload()
        self.customModelName = "food"
        self.foodKind = foodKind
        self.name = "food"

        if let resourceURL = foodKind.resourceURL {
            do {
                let scene = try SCNScene(url: resourceURL, options: nil)
                for node in scene.rootNode.childNodes {
                    node.removeFromParentNode()
                    self.addChildNode(node)
                }
            } catch {
                print("Failed to load \(foodKind.resourceName).usdz: \(error)")
            }
        } else {
            print("Missing bundled food asset: \(foodKind.resourceName).usdz")
        }

        self.prepareLoadedFoodModel()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func prepareLoadedFoodModel() {
        if childNodes.isEmpty {
            print("Using orange fallback sphere for \(foodKind?.resourceName ?? modelName)")
            let fallbackGeometry = SCNSphere(radius: 0.05)
            let fallbackMaterial = SCNMaterial()
            fallbackMaterial.diffuse.contents = UIColor.orange
            fallbackGeometry.materials = [fallbackMaterial]
            addChildNode(SCNNode(geometry: fallbackGeometry))
        }

        childNodes.forEach { node in
            node.name = node.name ?? "foodModel"
        }

        let (minBounds, maxBounds) = boundingBox
        let width = maxBounds.x - minBounds.x
        let height = maxBounds.y - minBounds.y
        let length = maxBounds.z - minBounds.z
        let maxDimension = Swift.max(width, Swift.max(height, length))

        if maxDimension > 0 {
            let targetSize: Float = 0.12
            let scaleFactor = targetSize / maxDimension
            scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
        }

        pivot = SCNMatrix4MakeTranslation(
            (minBounds.x + maxBounds.x) / 2,
            minBounds.y,
            (minBounds.z + maxBounds.z) / 2
        )
    }

    enum GeometryType {
        case foodSphere
        case animalBox
    }

    enum FoodKind: CaseIterable {
        case bread
        case flower
        case meat

        var resourceName: String {
            switch self {
            case .bread:
                return "bread-food"
            case .flower:
                return "flower-food"
            case .meat:
                return "meat-food"
            }
        }

        var resourceURL: URL? {
            let fileName = "\(resourceName).usdz"

            if let directURL = Bundle.main.url(forResource: resourceName, withExtension: "usdz") {
                return directURL
            }

            if let resourcesURL = Bundle.main.url(forResource: resourceName, withExtension: "usdz", subdirectory: "Resources") {
                return resourcesURL
            }

            guard let enumerator = FileManager.default.enumerator(
                at: Bundle.main.bundleURL,
                includingPropertiesForKeys: nil
            ) else {
                return nil
            }

            for case let fileURL as URL in enumerator where fileURL.lastPathComponent == fileName {
                return fileURL
            }

            return nil
        }

        var isCorrectForButterfly: Bool {
            self == .flower
        }
    }
}
