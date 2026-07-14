//
//  ViewController+ARSCNViewDelegate.swift
//  ARProject
//
//  Created by Nadia Putri Natali Lubis on 14/07/26.
//

import Foundation
import ARKit

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let pendingObject = sceneView.pendingVirtualObjects[anchor.identifier] else { return }
        node.addChildNode(pendingObject)
        sceneView.pendingVirtualObjects[anchor.identifier] = nil
    }
}
