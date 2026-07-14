//
//  VirtualObjectARView.swift
//  ARProject
//
//  Created by Nadia Putri Natali Lubis on 14/07/26.
//

import Foundation
import ARKit

extension VirtualObjectARView {
    /// Hit-tests the center of the screen against virtual scene nodes (not real-world surfaces)
    /// and returns the first ancestor node matching `name`.
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
