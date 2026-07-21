//
//  ARViewContainer.swift
//  ARProject
//
//  Created by Ferdiansyah Annora on 20/07/26.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var manager: ARManager

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsUserFaceTracking {
            config.userFaceTrackingEnabled = true
        }

        arView.session.delegate = context.coordinator
        arView.session.run(config)

        let camAnchor = AnchorEntity(.camera)
        arView.scene.addAnchor(camAnchor)
        manager.cameraAnchor = camAnchor

        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
        arView.scene.addAnchor(anchor)

        let sub = arView.scene.subscribe(to: SceneEvents.AnchoredStateChanged.self) { event in
            if event.isAnchored && event.anchor == anchor {
                DispatchQueue.main.async {
                    if manager.isCoaching {
                        withAnimation {
                            manager.isCoaching = false
                        }
                        let staticAnchor = AnchorEntity(world: anchor.transformMatrix(relativeTo: nil as Entity?))
                        anchor.scene?.addAnchor(staticAnchor)
                        manager.setup(cameraAnchor: camAnchor, planeAnchor: staticAnchor)
                    }
                }
            }
        }
        sub.store(in: &manager.subscriptions)

        let updateSub = arView.scene.subscribe(to: SceneEvents.Update.self) { _ in
            manager.updateScene()
        }
        updateSub.store(in: &manager.subscriptions)

        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.delegate = context.coordinator
        arView.addSubview(coachingOverlay)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(manager: manager)
    }

    class Coordinator: NSObject, ARSessionDelegate, ARCoachingOverlayViewDelegate {
        var manager: ARManager

        init(manager: ARManager) {
            self.manager = manager
        }

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard manager.showFactSheet && manager.isFactQuestionActive else { return }
            let now = CACurrentMediaTime()
            for faceAnchor in anchors.compactMap({ $0 as? ARFaceAnchor }) {
                manager.headGestureController.update(faceAnchor: faceAnchor, timestamp: now)
            }
        }

        func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
            DispatchQueue.main.async {
                self.manager.isCoaching = false
            }
        }
    }
}
