//
//  ViewController+Feeding.swift
//  ARProject
//
//  Created by Nadia Putri Natali Lubis on 14/07/26.
//
//  Core feeding mini-game logic: pick up food when it's held over the
//  "hand zone" long enough, then carry it to the animal and feed it.
//  Designed to work without any buttons, using dwell-time detection, so
//  young users don't need precise tapping.
//

import Foundation
import UIKit
import ARKit
import SceneKit

extension ViewController {

    /// Simple state machine: either the player has nothing in hand (`idle`),
    /// or they're carrying a specific food node (`carryingFood`).
    enum FeedingState {
        case idle
        case carryingFood(SCNNode)
    }

    /// Called ~10x/sec from `renderer(_:updateAtTime:)`. Which check runs
    /// depends on the current state — you can't try to feed the animal if
    /// you haven't picked up food yet.
    func checkFeedingProgress() {
        switch feedingState {
        case .idle:
            checkPickUpZone()
        case .carryingFood:
            checkFeedZone()
        }
    }

    // MARK: - Pick up food (aim food at the hand zone)

    /// Looks for a food node at the center of the screen, checks whether its
    /// on-screen (2D) projection falls inside the hand-zone rectangle, and if
    /// it's stayed there long enough, triggers the pick-up.
    private func checkPickUpZone() {
        guard let foodNode = sceneView.hitTestVirtualNode(named: "food") else {
            pickUpDwellTimer = 0
            return
        }

        /// Project the food's 3D world position down to a 2D point on screen,
        /// so we can compare it against the (2D, screen-space) hand zone rect.
        let screenPoint = sceneView.projectPoint(foodNode.worldPosition)
        let point2D = CGPoint(x: CGFloat(screenPoint.x), y: CGFloat(screenPoint.y))

        guard handZoneOverlay.zoneRect.contains(point2D) else {
            pickUpDwellTimer = 0
            return
        }

        /// Already inside the zone -> accumulate dwell time.
        pickUpDwellTimer += feedingCheckInterval
        if pickUpDwellTimer >= dwellThreshold {
            performPickUp(foodNode)
            pickUpDwellTimer = 0
        }
    }

    private func performPickUp(_ foodNode: SCNNode) {
        /// Detach from AR world tracking — once "held", the food should move with the camera, not stay pinned to a spot in the real world.
        if let virtualFood = foodNode as? VirtualObject, let anchor = virtualFood.anchor {
            session.remove(anchor: anchor)
            virtualFood.anchor = nil
        }
        foodNode.removeFromParentNode()

        /// Re-parent to the camera node (`pointOfView`) so the food stays centered on screen, roughly where the hand-zone graphics converge, regardless of how the user moves their phone.
        if let pov = sceneView.pointOfView {
            foodNode.transform = SCNMatrix4Identity
            foodNode.position = SCNVector3(0, 0.005, -0.35) // slightly below, ~35cm in front of camera
            pov.addChildNode(foodNode)
        }

        feedingState = .carryingFood(foodNode)
        handZoneOverlay.state = .grabbing
        statusLabel.text = "Makanan diambil! Arahkan ke hewan"
        flashStatus(success: true)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Briefly flashes the status label green/red for feedback, then fades
    /// back to its normal color.
    private func flashStatus(success: Bool) {
        UIView.animate(withDuration: 0.15) {
            self.statusLabel.backgroundColor = (success ? UIColor.systemGreen : UIColor.systemRed).withAlphaComponent(0.85)
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 0.5, options: []) {
                self.statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            }
        }
    }

    // MARK: - Feed the animal (aim the camera at the animal)

    private func checkFeedZone() {
        guard sceneView.hitTestVirtualNode(named: "animal") != nil else {
            feedDwellTimer = 0
            return
        }

        feedDwellTimer += feedingCheckInterval
        if feedDwellTimer >= dwellThreshold {
            performFeed()
            feedDwellTimer = 0
        }
    }

    private func performFeed() {
        guard case .carryingFood(let food) = feedingState else { return }

        let foodKind = (food as? VirtualObject)?.foodKind
        let animalAccepts = foodKind?.isCorrectForButterfly == true

        if animalAccepts {
            statusLabel.text = "Kupu-kupu suka flower!"
            food.removeFromParentNode()
        } else {
            statusLabel.text = "Kupu-kupu menolak makanan itu"
            flingAwayAndRemove(food)
        }

        flashStatus(success: animalAccepts)
        UINotificationFeedbackGenerator().notificationOccurred(animalAccepts ? .success : .warning)
        feedingState = .idle
        handZoneOverlay.state = .reaching
    }

    /// Flings the rejected food away from the camera (a little "bounced off" effect) and fades it out, then removes it from the scene.
    ///
    /// Because the food is currently parented to the camera (`pointOfView`), `SCNAction.move(by:)` here moves it in the camera's LOCAL coordinate space, where +Z points toward the viewer/away from what the camera is looking at. That's why moving by a positive Z reads as "away from the animal" instead of "toward" it — this was the fling-direction bug you fixed.
    private func flingAwayAndRemove(_ food: SCNNode) {
        /// Randomize left/right so rejected food doesn't always fly the same way.
        let sideDirection: Float = Bool.random() ? 1 : -1
        let sideDistance: Float = Float.random(in: 0.4...0.6) * sideDirection

        /// +Z = backward relative to the camera = away from the animal.
        /// A small +Y adds a bit of "pop up" so it reads as bounced, not just slid.
        let flingAction = SCNAction.move(by: SCNVector3(sideDistance, 0.2, 0.3), duration: 0.4)
        flingAction.timingMode = .easeOut
        let fadeAction = SCNAction.fadeOut(duration: 0.4)
        let group = SCNAction.group([flingAction, fadeAction])
        food.runAction(group) {
            food.removeFromParentNode()
        }
    }

    // MARK: - Actions

    @objc func didTapSpawnFood(_ sender: UIButton) {
        guard sceneView.scene.rootNode.childNode(withName: "animal", recursively: true) != nil else {
            statusLabel.text = "Spawn hewan dulu sebelum kasih makanan"
            return
        }
        sceneView.spawnFoodAroundAnimal()
        statusLabel.text = "Makanan muncul di sekitar hewan"

        /// The hand zone graphic is only relevant once there's food to pick up — keep it hidden the rest of the time (animal placement, plane scanning) so it doesn't clutter the screen.
        handZoneOverlay.isHidden = false
        view.bringSubviewToFront(handZoneOverlay)
    }
}
