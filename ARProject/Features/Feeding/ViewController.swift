//
//  ViewController.swift
//  ARProject
//
//  Created by Nadia Putri Natali Lubis on 14/07/26.
//

/*
 See the LICENSE.txt file for this sample’s licensing information.
 
 Abstract:
 Main view controller for the AR experience.
 */

import Foundation


import ARKit
import SceneKit
import UIKit

class ViewController: UIViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet var sceneView: VirtualObjectARView!
    
    @IBOutlet weak var addObjectButton: UIButton!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var upperControlsView: UIView!
    
    // MARK: Properties
    var feedingState: FeedingState = .idle

    let statusLabel = UILabel()
    let pickUpButton = UIButton(type: .system)
    let feedButton = UIButton(type: .system)
    
    

    // MARK: - UI Elements
    
    let coachingOverlay = ARCoachingOverlayView()
    
    /// The view controller that displays the status and "restart experience" UI.
//    lazy var statusViewController: StatusViewController = {
//        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
//    }()
    
    /// Coordinates the loading and unloading of reference nodes for virtual objects.
//    let virtualObjectLoader = VirtualObjectLoader()
    
    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "com.nadia.ARProject")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    @objc func showVirtualObjectSelectionViewController() {
        // 1. Get the current raycast query from the center screen / focus square alignment
        guard let query = sceneView.getRaycastQuery(for: .horizontal),
              let hitResult = sceneView.castRay(for: query).first else {
            let alert = UIAlertController(title: "Surface Not Found", message: "Please point at a flat floor surface.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        // 2. Perform the node updates safely on your serial queue
        updateQueue.async {
            // Spawn the animal at the hit result location
            self.sceneView.spawnAnimal(at: hitResult)
            
            // Update UI states on the main thread
            DispatchQueue.main.sync {
                
                // Optional: Hide the default add button or change its state
//                self.addObjectButton.isHidden = true
            }
        }
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
//        sceneView.session.delegate = self
        
        // Set up coaching overlay.
        setupCoachingOverlay()

        // Set up scene content.
//        sceneView.scene.roo÷tNode.addChildNode(focusSquare)

        // Hook up status view controller callback(s).
//        statusViewController.restartExperienceHandler = { [unowned self] in
//            self.restartExperience()
//        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showVirtualObjectSelectionViewController))
            
            // Comment out this gesture delegate line:
            // tapGesture.delegate = self
            sceneView.addGestureRecognizer(tapGesture)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed to avoid interuppting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true

        // Start the `ARSession`.
        resetTracking()
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        session.pause()
    }

    // MARK: - Session management
    
    /// Creates a new AR configuration to run on the `session`.
    func resetTracking() {
//        virtualObjectInteraction.selectedObject = nil
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        if #available(iOS 12.0, *) {
            configuration.environmentTexturing = .automatic
        }
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

    }

    // MARK: - Focus Square

//    func updateFocusSquare(isObjectVisible: Bool) {
//        if isObjectVisible || coachingOverlay.isActive {
////            focusSquare.hide()
//        } else {
////            focusSquare.unhide()
//            statusViewController.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
//        }
//        
//        // Perform ray casting only when ARKit tracking is in a good state.
//        if let camera = session.currentFrame?.camera, case .normal = camera.trackingState,
//            let query = sceneView.getRaycastQuery(),
//            let result = sceneView.castRay(for: query).first {
//            
////            updateQueue.async {
////                self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
////                self.focusSquare.state = .detecting(raycastResult: result, camera: camera)
////            }
//            
//            if !coachingOverlay.isActive {
//                addObjectButton.isHidden = false
//            }
//            statusViewController.cancelScheduledMessage(for: .focusSquare)
//        } else {
//            updateQueue.async {
////                self.focusSquare.state = .initializing
//                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
//            }
//            addObjectButton.isHidden = true
//            objectsViewController?.dismiss(animated: false, completion: nil)
//        }
//    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.blurView.isHidden = true
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
    override func loadView() {
        super.loadView()
        
        // 1. Manually initialize the main custom AR View
        let customARView = VirtualObjectARView(frame: UIScreen.main.bounds)
        self.sceneView = customARView
        self.view = customARView
        
        // 2. Status label — pengganti sementara StatusViewController karena gak pake storyboard
        statusLabel.frame = CGRect(x: 20, y: 60, width: UIScreen.main.bounds.width - 40, height: 40)
        statusLabel.textAlignment = .center
        statusLabel.textColor = .white
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        statusLabel.layer.cornerRadius = 8
        statusLabel.layer.masksToBounds = true
        statusLabel.text = "Ketuk layar untuk spawn hewan"
        self.view.addSubview(statusLabel)
        
        // 3. Pick Up Food button
        pickUpButton.frame = CGRect(x: 40, y: UIScreen.main.bounds.height - 100, width: 140, height: 50)
        pickUpButton.setTitle("Ambil Makanan", for: .normal)
        pickUpButton.backgroundColor = .systemOrange
        pickUpButton.setTitleColor(.white, for: .normal)
        pickUpButton.layer.cornerRadius = 8
        pickUpButton.addTarget(self, action: #selector(didTapPickUpFood(_:)), for: .touchUpInside)
        self.view.addSubview(pickUpButton)
        
        // tambahin di loadView(), sebelah pickUpButton
        let spawnFoodButton = UIButton(type: .system)
        spawnFoodButton.frame = CGRect(x: 40, y: UIScreen.main.bounds.height - 160, width: 140, height: 40)
        spawnFoodButton.setTitle("Spawn Food", for: .normal)
        spawnFoodButton.backgroundColor = .systemPurple
        spawnFoodButton.setTitleColor(.white, for: .normal)
        spawnFoodButton.layer.cornerRadius = 8
        spawnFoodButton.addTarget(self, action: #selector(didTapSpawnFood(_:)), for: .touchUpInside)
        self.view.addSubview(spawnFoodButton)
        
        // 4. Feed Animal button
        feedButton.frame = CGRect(x: UIScreen.main.bounds.width - 180, y: UIScreen.main.bounds.height - 100, width: 140, height: 50)
        feedButton.setTitle("Kasih Makan", for: .normal)
        feedButton.backgroundColor = .systemGreen
        feedButton.setTitleColor(.white, for: .normal)
        feedButton.layer.cornerRadius = 8
        feedButton.isEnabled = false
        feedButton.addTarget(self, action: #selector(didTapFeedAnimal(_:)), for: .touchUpInside)
        self.view.addSubview(feedButton)
    }
    
    // MARK: - Temporary Action Triggers

//    @objc func didTapGiveFoodButton(_ sender: UIButton) {
//        // 1. Ensure the scene updates run safely on your serial queue to prevent crashes
//        updateQueue.async {
//            // 2. Call the spawning method we added to VirtualObjectARView
//            self.sceneView.spawnFoodAroundAnimal()
//            
//            // 3. Update the UI state message on the main thread safely
//            DispatchQueue.main.async {
//                // Optional: Disable the button so you can only spawn the 3 foods once per test
//                sender.isEnabled = false
//            }
//        }
//    }

}

