//
//  ViewController+ARSCNViewDelegate.swift
//  ARProject
//
//  Created by Nadia Putri Natali Lubis on 14/07/26.
//
//  This extension holds the two SceneKit renderer callbacks this project
//  actually relies on: syncing node position to its ARAnchor every frame,
//  and a throttled per-frame check for the feeding game logic.
//

import Foundation
import ARKit

extension ViewController: ARSCNViewDelegate {
    /// Called every time ARKit re-estimates the position/orientation of an
    /// existing anchor (which happens continuously as ARKit refines its
    /// understanding of the world). This is what keeps a placed object glued
    /// to the real-world surface as tracking improves, instead of drifting.
    ///
    /// Note: we read `anchor.transform.columns.3` (the translation/position
    /// column of the 4x4 transform matrix) directly, rather than using a
    /// `.translation` convenience property. That's because RealityKit adds
    /// its own `.translation` extension on matrix types that can conflict
    /// with a custom one defined elsewhere in ARKit sample code — reading
    /// `columns.3` directly sidesteps the ambiguity entirely.
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        updateQueue.async {
            guard let object = self.sceneView.allSpawnedObjects.first(where: { $0.anchor?.identifier == anchor.identifier }) else {
                return
            }
            let t = anchor.transform.columns.3
            object.simdPosition = SIMD3<Float>(t.x, t.y, t.z)
        }
    }

    /// SceneKit calls this on (almost) every rendered frame — roughly 60
    /// times a second. Running hit-tests and dwell-timer math that often is
    /// wasteful, so we throttle it down to `feedingCheckInterval` (10x/sec)
    /// using a simple "has enough time passed" gate, plus an `isCheckingFeeding`
    /// flag so we never have two checks running concurrently if one takes
    /// longer than expected.
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
