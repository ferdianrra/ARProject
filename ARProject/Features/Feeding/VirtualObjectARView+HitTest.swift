//
//  VirtualObjectARView.swift
//  ARProject
//
//  Created by Nadia Putri Natali Lubis on 14/07/26.
//
//  Small helper used by the feeding logic to answer "what named virtual
//  object is currently at the center of the screen?" — this is how the game
//  detects "player is aiming at the food" or "player is aiming at the animal"
//  without needing any tap/gesture from the user.
//

import Foundation
import ARKit

extension VirtualObjectARView {
    /// Hit-tests the center of the screen against virtual scene nodes (NOT
    /// real-world surfaces — this is a SceneKit hit-test against rendered
    /// geometry, unlike the ARKit raycasts used for placing objects on the
    /// floor) and returns the first ancestor node matching `name`.
    ///
    /// Walking up via `node.parent` matters because the actual mesh that
    /// gets hit is the inner `wrapperNode` created in VirtualObject's
    /// initializer, not the VirtualObject itself — so we climb the hierarchy
    /// until we find a node carrying the name we're looking for (e.g. "food"
    /// or "animal").
    func hitTestVirtualNode(named name: String) -> SCNNode? {
        let results = hitTest(screenCenter, options: [
            .searchMode: SCNHitTestSearchMode.all.rawValue
        ])

        for result in results {
            var node: SCNNode? = result.node
            while node != nil {
                if node?.name == name {
                    return node
                }
                node = node?.parent
            }
        }
        return nil
    }
}
