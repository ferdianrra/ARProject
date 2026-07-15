//
//  ViewController+CoachingOverlay.swift
//  ARProject
//
//  Created by Nadia Putri Natali Lubis on 14/07/26.
//
//  ARCoachingOverlayView is a system-provided UI (Apple draws it for you)
//  that shows a "move your device around" animation while ARKit is still
//  figuring out the environment — e.g. right after launch, before enough of
//  the floor has been scanned to detect a horizontal plane. This extension
//  wires it up and reacts to it activating/deactivating.
//

import UIKit
import ARKit

extension ViewController: ARCoachingOverlayViewDelegate {
    /// Sets up the overlay's constraints (pinned to fill the whole view) and
    /// tells it what "goal" to coach the user toward.
    func setupCoachingOverlay() {
        coachingOverlay.session = sceneView.session
        coachingOverlay.delegate = self

        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(coachingOverlay)

        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: view.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])

        setActivatesAutomatically()

        // Most of the virtual objects in this sample require a horizontal surface,
        // therefore coach the user to find a horizontal plane.
        setGoal()
    }

    func setActivatesAutomatically() {
        coachingOverlay.activatesAutomatically = true
    }

    func setGoal() {
        coachingOverlay.goal = .horizontalPlane
    }
}
