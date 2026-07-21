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

        func checkForFloorUnderCamera() {
            guard manager.isCoaching, let arView = arView, let camAnchor = camAnchor else { return }
            
            let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
            var results = arView.raycast(from: center, allowing: .existingPlaneGeometry, alignment: .horizontal)
            if results.isEmpty {
                results = arView.raycast(from: center, allowing: .existingPlaneInfinite, alignment: .horizontal)
            }
            
            guard let firstResult = results.first,
                  let planeAnchor = firstResult.anchor as? ARPlaneAnchor else { return }
            
            let planeHeight = planeAnchor.transform.columns.3.y
            
            var isValidFloor = false
            if ARPlaneAnchor.isClassificationSupported {
                switch planeAnchor.classification {
                case .floor:
                    // If classified as floor, ensure it's not unreasonably high (must be at least 50cm below camera)
                    isValidFloor = planeHeight <= -0.5
                case .none(_):
                    // If undetermined/unknown/notAvailable, must be at least 80cm below initial camera
                    isValidFloor = planeHeight <= -0.8
                default:
                    // Explicitly classified as table, seat, wall, etc. -> REJECT
                    isValidFloor = false
                }
            } else {
                // Device doesn't support classification: must be at least 80cm below initial camera
                isValidFloor = planeHeight <= -0.8
            }
            
            if isValidFloor {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, self.manager.isCoaching else { return }
                    
                    withAnimation {
                        self.manager.isCoaching = false
                    }
                    
                    let planeAnchorEntity = AnchorEntity(anchor: planeAnchor)
                    arView.scene.addAnchor(planeAnchorEntity)
                    
                    self.manager.setup(cameraAnchor: camAnchor, planeAnchor: planeAnchorEntity)
                }
            }
        }

        func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
            DispatchQueue.main.async {
                if self.manager.anchorRef != nil {
                    self.manager.isCoaching = false
                } else {
                    // Table/other plane was detected but not validated as a floor.
                    // Reactivate coaching overlay to keep scanning.
                    coachingOverlayView.setActive(true, animated: true)
                }
            }
        }
    }
}
