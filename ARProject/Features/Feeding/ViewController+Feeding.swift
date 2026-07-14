//
//  ViewController+Feeding.swift
//  ARProject
//
//  Created by Nadia Putri Natali Lubis on 14/07/26.
//

import Foundation
import UIKit
import ARKit
import SceneKit

extension ViewController {

    enum FeedingState {
        case idle
        case carryingFood(SCNNode)
    }

    // MARK: - Actions
    
    @objc func didTapSpawnFood(_ sender: UIButton) {
        guard sceneView.scene.rootNode.childNode(withName: "animal", recursively: true) != nil else {
            statusLabel.text = "Spawn hewan dulu sebelum kasih makanan"
            return
        }
        sceneView.spawnFoodAroundAnimal()
        statusLabel.text = "Makanan muncul di sekitar hewan"
    }

    @objc func didTapPickUpFood(_ sender: UIButton) {
        guard case .idle = feedingState else {
            statusLabel.text = "Kamu udah pegang makanan"
            return
        }

        guard let foodNode = sceneView.hitTestVirtualNode(named: "food") else {
            print("DEBUG: no food node found in scene")
            statusLabel.text = "Arahkan ke makanan dulu"
            return
        }

        // Detach from AR anchor tracking since it's now "held", not placed in the world.
        if let virtualFood = foodNode as? VirtualObject, let anchor = virtualFood.anchor {
            session.remove(anchor: anchor)
            virtualFood.anchor = nil
        }
        foodNode.removeFromParentNode()

        feedingState = .carryingFood(foodNode)
        statusLabel.text = "Makanan diambil! Arahkan ke hewan."
        pickUpButton.isEnabled = false
        feedButton.isEnabled = true
    }

    @objc func didTapFeedAnimal(_ sender: UIButton) {
        guard case .carryingFood(let food) = feedingState else {
            statusLabel.text = "Ambil makanan dulu"
            return
        }

        guard sceneView.hitTestVirtualNode(named: "animal") != nil else {
            statusLabel.text = "Arahkan ke hewan dulu"
            return
        }

        // TODO: ganti Bool.random() ini dengan logic asli (misal: preferensi makanan tertentu)
        let animalAccepts = Bool.random()

        if animalAccepts {
            statusLabel.text = "Hewan suka makanannya! 🐾"
            food.removeFromParentNode() // makanan "dimakan", hilang dari scene
        } else {
            statusLabel.text = "Hewan menolak makanannya 😾"
            // taruh lagi makanannya balik ke dunia di depan animal, bukan dibuang
            respawnRejectedFood(food)
        }

        feedingState = .idle
        pickUpButton.isEnabled = true
        feedButton.isEnabled = false
    }

    // MARK: - Helpers

    private func respawnRejectedFood(_ food: SCNNode) {
        guard let animalNode = sceneView.scene.rootNode.childNode(withName: "animal", recursively: true) else {
            return
        }
        var transform = animalNode.simdWorldTransform
        transform.columns.3.z += 0.3 // taruh 30cm di depan animal (sumbu Z lokal dunia, sesuaikan kalau perlu)

        let anchor = ARAnchor(transform: transform)
        if let virtualFood = food as? VirtualObject {
            virtualFood.anchor = anchor
        }
        sceneView.pendingVirtualObjects[anchor.identifier] = food as? VirtualObject
        session.add(anchor: anchor)
    }
}
