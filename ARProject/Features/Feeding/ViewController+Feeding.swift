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
    
    /// Dipanggil tiap frame dari renderer(_:updateAtTime:)
    func checkFeedingProgress() {
        switch feedingState {
        case .idle:
            checkPickUpZone()
        case .carryingFood:
            checkFeedZone()
        }
    }
    
    // MARK: - Ambil makanan (arahkan food ke celah tangan)
    
    private func checkPickUpZone() {
        guard let foodNode = sceneView.hitTestVirtualNode(named: "food") else {
            pickUpDwellTimer = 0
            return
        }
        
        // Proyeksikan posisi 3D makanan ke koordinat layar 2D
        let screenPoint = sceneView.projectPoint(foodNode.worldPosition)
        let point2D = CGPoint(x: CGFloat(screenPoint.x), y: CGFloat(screenPoint.y))
        
        guard handZoneOverlay.zoneRect.contains(point2D) else {
            pickUpDwellTimer = 0
            return
        }
        
        // Sudah di zona -> akumulasi dwell time
        pickUpDwellTimer += feedingCheckInterval
        if pickUpDwellTimer >= dwellThreshold {
            performPickUp(foodNode)
            pickUpDwellTimer = 0
        }
    }
    
    private func performPickUp(_ foodNode: SCNNode) {
        if let virtualFood = foodNode as? VirtualObject, let anchor = virtualFood.anchor {
            session.remove(anchor: anchor)
            virtualFood.anchor = nil
        }
        foodNode.removeFromParentNode()
        
        if let pov = sceneView.pointOfView {
            foodNode.transform = SCNMatrix4Identity
            foodNode.position = SCNVector3(0, -0.05, -0.35) // sedikit ke bawah, ~35cm di depan kamera
            pov.addChildNode(foodNode)
        }
        
        feedingState = .carryingFood(foodNode)
        statusLabel.text = "Makanan diambil! Arahkan ke hewan 🐾"
        flashStatus(success: true)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    // ViewController+Feeding.swift
    private func flashStatus(success: Bool) {
        UIView.animate(withDuration: 0.15) {
            self.statusLabel.backgroundColor = (success ? UIColor.systemGreen : UIColor.systemRed).withAlphaComponent(0.85)
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 0.5, options: []) {
                self.statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            }
        }
    }
    
    // MARK: - Kasih makan (arahkan kamera ke animal)
    
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
        
        // TODO: ganti logic asli (misal preferensi makanan tertentu)
        let animalAccepts = Bool.random()
        
        if animalAccepts {
            statusLabel.text = "Hewan suka makanannya! 🐾"
            food.removeFromParentNode()
        } else {
            statusLabel.text = "Hewan menolak makanannya 😾"
            flingAwayAndRemove(food)
        }
        
        flashStatus(success: animalAccepts)
        UINotificationFeedbackGenerator().notificationOccurred(animalAccepts ? .success : .warning)
        feedingState = .idle
    }
    
    /// Melempar makanan menjauh dari kamera (efek "ditolak/mental") lalu menghapusnya dari scene.
    private func flingAwayAndRemove(_ food: SCNNode) {
        let randomX = Float.random(in: -0.3...0.3)
        let flingAction = SCNAction.move(by: SCNVector3(randomX, 0.25, -0.5), duration: 0.4)
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
            flingAwayAndRemove(food)
        }
        
        feedingState = .idle
        pickUpButton.isEnabled = true
        feedButton.isEnabled = false
    }
    
    // MARK: - Helpers
    
}
