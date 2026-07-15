//
//  ViewController+ARSCNViewDelegate.swift
//  ARProject
//
//  Created by Nadia Putri Natali Lubis on 14/07/26.
//

import Foundation
import ARKit

extension ViewController: ARSCNViewDelegate {
    //    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    //        guard let pendingObject = sceneView.pendingVirtualObjects[anchor.identifier] else { return }
    //        node.addChildNode(pendingObject)
    //        sceneView.pendingVirtualObjects[anchor.identifier] = nil
    //
    //        if pendingObject.modelName == "animal" {
    //            sceneView.spawnFoodAroundAnimal()
    //        }
    //}
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        updateQueue.async {
            guard let object = self.sceneView.allSpawnedObjects.first(where: { $0.anchor?.identifier == anchor.identifier }) else {
                return
            }
            let t = anchor.transform.columns.3
            object.simdPosition = SIMD3<Float>(t.x, t.y, t.z)
        }
    }
    
    // Throttled dwell-check untuk feeding logic (dari sebelumnya) — TIDAK
    // berhubungan dengan sinkronisasi anchor, cuma untuk deteksi pick-up/feed.
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard time - lastFeedingCheckTime >= feedingCheckInterval else { return }
        lastFeedingCheckTime = time
        
        guard !isCheckingFeeding else { return }
        isCheckingFeeding = true
        
        DispatchQueue.main.async { [weak self] in
            self?.checkFeedingProgress()
            self?.isCheckingFeeding = false
        }
    }
}
