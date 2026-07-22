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
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            config.frameSemantics.insert(.personSegmentationWithDepth)
        } else if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentation) {
            config.frameSemantics.insert(.personSegmentation)
        }
        
        if ARWorldTrackingConfiguration.supportsUserFaceTracking {
            config.userFaceTrackingEnabled = true
        }

        arView.session.delegate = context.coordinator
        arView.session.run(config)
        
        arView.environment.sceneUnderstanding.options.insert([.occlusion, .receivesLighting])
        
        manager.arView = arView

        let camAnchor = AnchorEntity(.camera)
        arView.scene.addAnchor(camAnchor)
        manager.cameraAnchor = camAnchor

        let coordinator = context.coordinator
        coordinator.arView = arView
        coordinator.camAnchor = camAnchor

        let updateSub = arView.scene.subscribe(to: SceneEvents.Update.self) { _ in
            manager.updateScene()
            coordinator.checkForFloorUnderCamera()
        }
        updateSub.store(in: &manager.subscriptions)

        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.delegate = coordinator
        arView.addSubview(coachingOverlay)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(manager: manager)
    }

    class Coordinator: NSObject, ARSessionDelegate, ARCoachingOverlayViewDelegate {
        var manager: ARManager
        weak var arView: ARView?
        weak var camAnchor: AnchorEntity?

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

        // MARK: - Per-frame floor check (called from SceneEvents.Update)
        func checkForFloorUnderCamera() {
            // Run during coaching phase AND during portal-guide phase (until placed)
            guard !manager.isPlaced, let arView = arView, let camAnchor = camAnchor else {
                // Already placed — ensure portals are gone
                manager.isFloorTargeted = false
                return
            }

            let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
            // existingPlaneGeometry only — no infinite fallback.
            // If camera isn't directly over real floor geometry, indicator hides.
            let results = arView.raycast(from: center, allowing: .existingPlaneGeometry, alignment: .horizontal)

            guard let firstResult = results.first,
                  let planeAnchor = firstResult.anchor as? ARPlaneAnchor else {
                // No plane under camera center → hide portals, show guidance label
                DispatchQueue.main.async { [weak self] in
                    self?.manager.isFloorTargeted = false
                }
                return
            }

            let planeHeight = planeAnchor.transform.columns.3.y

            var isValidFloor = false
            if ARPlaneAnchor.isClassificationSupported {
                switch planeAnchor.classification {
                case .floor:
                    // Classified as floor: must be at least 50cm below camera start
                    isValidFloor = planeHeight <= -0.5
                case .none(_):
                    // Unclassified: stricter threshold of 1.0m to reject tables (~75cm)
                    isValidFloor = planeHeight <= -1.0
                default:
                    // Explicitly table, seat, wall, etc. → reject
                    isValidFloor = false
                }
            } else {
                // Classification not supported: use height fallback
                isValidFloor = planeHeight <= -0.8
            }

            if isValidFloor {
                // Extract world position of the raycast hit point
                let worldPos = SIMD3<Float>(
                    firstResult.worldTransform.columns.3.x,
                    firstResult.worldTransform.columns.3.y,
                    firstResult.worldTransform.columns.3.z
                )

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }

                    // Update state so ContentView shows portals + correct label
                    self.manager.isFloorTargeted = true

                    // If still in coaching phase → dismiss coaching and setup anchors
                    if self.manager.isCoaching {
                        withAnimation {
                            self.manager.isCoaching = false
                        }
                        let planeAnchorEntity = AnchorEntity(anchor: planeAnchor)
                        arView.scene.addAnchor(planeAnchorEntity)
                        self.manager.setup(cameraAnchor: camAnchor, planeAnchor: planeAnchorEntity)
                    }
                }
            } else {
                // Floor not valid under camera — hide portals, show guidance label
                DispatchQueue.main.async { [weak self] in
                    self?.manager.isFloorTargeted = false
                }
            }
        }

        func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
            DispatchQueue.main.async {
                if self.manager.anchorRef != nil {
                    self.manager.isCoaching = false
                } else {
                    // No valid floor confirmed yet — keep coaching active
                    coachingOverlayView.setActive(true, animated: true)
                }
            }
        }
    }
}

