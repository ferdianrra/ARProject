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

        if pendingObject.modelName == "animal" {
            sceneView.spawnFoodAroundAnimal()
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Throttle: cek posisi 10x/detik, cukup buat dwell detection, jauh lebih ringan dari 60x/detik
        guard time - lastFeedingCheckTime >= feedingCheckInterval else { return }
        lastFeedingCheckTime = time

        guard !isCheckingFeeding else { return } // guard tambahan biar gak numpuk kalau ada yang telat
        isCheckingFeeding = true

        DispatchQueue.main.async { [weak self] in
            self?.checkFeedingProgress()
            self?.isCheckingFeeding = false
        }
    }
}
