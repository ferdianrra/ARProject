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
import Vision

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var manager: ARManager

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        config.frameSemantics.insert(.personSegmentationWithDepth)
        
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
        
//        arView.environment.sceneUnderstanding.options.insert([.occlusion, .receivesLighting])
        arView.environment.sceneUnderstanding.options.insert([.receivesLighting, .physics])
        

        
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

        // MARK: - Call-the-animal via hand gesture
        private var currentHandBuffer: CVPixelBuffer?
        private let handVisionQueue = DispatchQueue(label: "com.arproject.animalCallVisionQueue")
        private lazy var handPoseRequest: VNDetectHumanHandPoseRequest = {
            let request = VNDetectHumanHandPoseRequest(completionHandler: { [weak self] request, error in
                self?.processHandPose(for: request, error: error)
            })
            request.maximumHandCount = 1
            return request
        }()
        private let handCurlCallController = HandCurlCallController()
        private let callAnimalController = CallAnimalController()
        
        // Feeding Gesture State
        private var isCurrentlyPinched = false
        private var framesSincePinchLost = 0

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

        // MARK: - Per-frame hand-pose check (call-the-animal gesture)
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // Only worth running at all once placed and inside a portal —
            // this app already does scene reconstruction + person
            // segmentation + occlusion/physics every frame, so running Vision
            // hand-pose continuously on top of that (even during placement,
            // when it can never fire anyway) adds real, avoidable CPU load.
            guard manager.isPlaced, manager.spots.contains(where: { $0.isNear }) else { return }
            guard currentHandBuffer == nil, case .normal = frame.camera.trackingState else { return }
            currentHandBuffer = frame.capturedImage

            let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentHandBuffer!, options: [:])
            handVisionQueue.async { [weak self] in
                guard let self else { return }
                defer { self.currentHandBuffer = nil }
                do {
                    try requestHandler.perform([self.handPoseRequest])
                } catch {
                    print("Hand-pose Vision error: \(error)")
                }
            }
        }

        private func processHandPose(for request: VNRequest, error: Error?) {
            guard let results = request.results as? [VNHumanHandPoseObservation], let hand = results.first else { return }

            let shouldCallAnimal = handCurlCallController.update(hand: hand)
            
            var normalizedPinchMidpoint: CGPoint?
            var currentPinchState = false
            
            if let thumbTip = try? hand.recognizedPoint(.thumbTip),
               let indexTip = try? hand.recognizedPoint(.indexTip),
               let wrist = try? hand.recognizedPoint(.wrist),
               let middleBase = try? hand.recognizedPoint(.middleMCP),
               thumbTip.confidence > 0.5, indexTip.confidence > 0.5,
               wrist.confidence > 0.5, middleBase.confidence > 0.5 {
                
                let handLength = hypot(wrist.location.x - middleBase.location.x,
                                       wrist.location.y - middleBase.location.y)
                let pinchDistance = hypot(thumbTip.location.x - indexTip.location.x,
                                          thumbTip.location.y - indexTip.location.y)
                let relativeDistance = pinchDistance / max(handLength, 0.01)
                
                if !isCurrentlyPinched && relativeDistance < 0.35 {
                    isCurrentlyPinched = true
                    framesSincePinchLost = 0
                } else if isCurrentlyPinched && relativeDistance > 0.65 {
                    framesSincePinchLost += 1
                    if framesSincePinchLost > 8 {
                        isCurrentlyPinched = false
                    }
                } else if isCurrentlyPinched && relativeDistance <= 0.65 {
                    framesSincePinchLost = 0
                }
                
                normalizedPinchMidpoint = CGPoint(
                    x: (wrist.location.x + middleBase.location.x) / 2.0,
                    y: (wrist.location.y + middleBase.location.y) / 2.0
                )
            } else {
                if isCurrentlyPinched {
                    framesSincePinchLost += 1
                    if framesSincePinchLost > 8 {
                        isCurrentlyPinched = false
                    }
                }
            }
            
            currentPinchState = isCurrentlyPinched

            DispatchQueue.main.async { [weak self] in
                guard let self, self.manager.spots.contains(where: { $0.isNear }) else { return }
                
                if shouldCallAnimal && !self.manager.isFeedingActive {
                    self.callAnimalController.callAnimal(manager: self.manager)
                }
                
                if self.manager.isFeedingActive {
                    self.manager.feedingController.update(manager: self.manager, isGrabbing: currentPinchState, normalizedPinchMidpoint: normalizedPinchMidpoint)
                }
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

