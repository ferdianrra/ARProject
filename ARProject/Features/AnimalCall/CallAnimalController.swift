import RealityKit
import simd
import Foundation

/// Moves the currently-near spot's animal from wherever it is to a point in
/// front of the camera, on the plane it was placed on, with an eased
/// turn-and-travel motion — triggered by the hand-curl gesture (see
/// HandCurlCallController) while inside that animal's portal.
///
/// Ground animals (non-butterfly) don't wander at all today — they're placed
/// once and stand still — so for them this is just a walk-to-camera with
/// nothing to suppress/resume. Butterflies wander continuously via
/// `spot.wanderTimer`, so this also pauses and later resumes that.
class CallAnimalController {
    /// How long the animal stays put after arriving before wandering resumes
    /// automatically (butterflies only — startWandering no-ops for other
    /// animal types). Cancelled and restarted if called again in the
    /// meantime, so repeat calls don't stack up multiple pending resumes.
    private let idleBeforeResumingWander: TimeInterval = 8.0
    private var pendingWanderResume: DispatchWorkItem?

    func callAnimal(manager: ARManager) {
        guard let spot = manager.spots.first(where: { $0.isNear }),
              let animal = spot.animalModel,
              let camera = manager.cameraAnchor else { return }

        pendingWanderResume?.cancel()
        spot.wanderTimer?.invalidate()
        spot.wanderTimer = nil

        // Yaw-only heading for DIRECTION, robust to pitch — using the
        // camera's right vector instead of forward, since right stays in
        // the horizontal plane at any tilt while forward degenerates near
        // straight up/down.
        let right3D = camera.orientation(relativeTo: nil).act(SIMD3<Float>(1, 0, 0))
        let flatForward = normalize(cross(SIMD3<Float>(0, 1, 0), SIMD3<Float>(right3D.x, 0, right3D.z)))

        // Tilt-responsive distance: look down more -> appears closer.
        let trueForward = camera.orientation(relativeTo: nil).act(SIMD3<Float>(0, 0, -1))
        let downTilt = max(0, -trueForward.y) // 0 = level/up, 1 = straight down
        let minDistance: Float = 0.4
        let maxDistance: Float = 0.9
        let distanceFromCamera = maxDistance - (maxDistance - minDistance) * downTilt

        let targetWorld = camera.position(relativeTo: nil) + flatForward * distanceFromCamera
        var targetLocal = manager.parentContainer.convert(position: targetWorld, from: nil)

        // Height: this animal type's normal height (matches the same
        // convention startWandering/stopWandering already use elsewhere),
        // not a tilt-blend toward the floor — that was tuned specifically
        // for one flying-only scenario and doesn't generalize to ground
        // animals that already live at their own fixed height.
        targetLocal.y = manager.heightOffset(for: spot)

        let currentLocal = animal.position(relativeTo: manager.parentContainer)
        let delta = targetLocal - currentLocal
        let distance = simd_length(SIMD2<Float>(delta.x, delta.z))

        guard distance > 0.05 else {
            scheduleWanderResume(manager: manager, spot: spot)
            return
        }

        let speed: Float = 0.5 // m/s
        let duration = Double(min(max(distance / speed, 0.6), 3.0))

        // Face the camera at the destination, not the direction of travel —
        // a called animal should end up looking at whoever called it,
        // regardless of the path it took to get there.
        let cameraLocal = manager.parentContainer.convert(position: camera.position(relativeTo: nil), from: nil)
        let towardCamera = normalize(SIMD3<Float>(cameraLocal.x - targetLocal.x, 0, cameraLocal.z - targetLocal.z))
        let facing = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: towardCamera)

        var targetTransform = animal.transform
        targetTransform.translation = targetLocal
        targetTransform.rotation = facing

        // No manual cancellation needed for a repeat call mid-move: RealityKit
        // replaces an in-flight transform animation on the same entity when
        // move(to:) is called again, so this cleanly retargets rather than
        // stacking — same reason a repeat call mid-wander-step interrupts
        // and heads to camera immediately instead of finishing the wander
        // step first.
        animal.move(to: targetTransform, relativeTo: manager.parentContainer, duration: duration, timingFunction: .easeInOut)

        scheduleWanderResume(manager: manager, spot: spot, afterTravel: duration)
    }

    private func scheduleWanderResume(manager: ARManager, spot: ARSpot, afterTravel travelDuration: TimeInterval = 0) {
        let workItem = DispatchWorkItem { [weak manager, weak spot] in
            guard let manager, let spot, spot.isNear, let animalModel = spot.animalModel else { return }
            // Do not resume wandering if feeding mode is active!
            if manager.isFeedingActive { return }
            manager.wanderController.startWandering(animalModel, at: spot, anchor: manager.parentContainer, yHeight: manager.heightOffset(for: spot))
        }
        pendingWanderResume = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + travelDuration + idleBeforeResumingWander, execute: workItem)
    }
}
