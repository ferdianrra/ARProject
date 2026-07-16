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
    
    // MARK: Properties

    /// Tracks whether the player is empty-handed or currently "holding" a food node.
    /// Read this together with `checkFeedingProgress()` in ViewController+Feeding.swift.
    var feedingState: FeedingState = .idle
    
    /// Accumulates time (in seconds) while the player's gaze/food stays inside the
    /// pick-up zone. Reset to 0 the moment the food leaves the zone. Once it crosses
    /// `dwellThreshold`, the pick-up action fires automatically — this is what lets
    /// young users interact without needing to tap a button.
    var pickUpDwellTimer: TimeInterval = 0
    var feedDwellTimer: TimeInterval = 0
    
    /// How long (seconds) something needs to "dwell" in the target zone before
    /// the app treats it as a confirmed action.
    let dwellThreshold: TimeInterval = 0.8
    
    /// The two-diagonal-rectangle overlay that shows the player where to aim to
    /// pick up / feed. Hidden by default; shown only after "Spawn Food" is tapped.
    var handZoneOverlay: HandZoneOverlayView!
    
    let statusLabel = UILabel()
    
    /// Throttling for the per-frame feeding check (see ViewController+ARSCNViewDelegate.swift).
    /// SceneKit's renderer callback fires every frame (~60x/sec); we don't need to
    /// run hit-testing that often, so we only run the check every `feedingCheckInterval`.
    var lastFeedingCheckTime: TimeInterval = 0
    let feedingCheckInterval: TimeInterval = 1.0 / 10.0
    var isCheckingFeeding = false
    
    var spawnFoodButton: UIButton!
    
    

    // MARK: - UI Elements
    
    let coachingOverlay = ARCoachingOverlayView()
        
    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    /// ARAnchors from a single thread. ARKit/SceneKit calls can come from
    /// different threads (main thread for UI, renderer thread for delegate
    /// callbacks); mutating the scene graph from two threads at once is a
    /// classic crash source, so everything that touches nodes/anchors goes
    /// through `updateQueue.async { ... }`.
    let updateQueue = DispatchQueue(label: "com.nadia.ARProject")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    /// Tap handler for placing the animal. Fires a raycast from the center of
    /// the screen (not from the tap location — see `getRaycastQuery`), and if
    /// it hits a detected horizontal plane, spawns the animal there.
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
            }
        }
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        
        /// Set up coaching overlay (the "move your phone around" system UI
        /// that appears while ARKit is still detecting a surface).
        setupCoachingOverlay()

        /// Tap anywhere on screen -> try to place the animal.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showVirtualObjectSelectionViewController))
            sceneView.addGestureRecognizer(tapGesture)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        /// Prevent the screen from being dimmed to avoid interuppting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true

        /// Start the `ARSession`.
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
    /// `.resetTracking` + `.removeExistingAnchors` wipes any previous
    /// world-tracking state, which is what you want on a fresh app launch,
    /// but be aware it also removes any anchors you've placed if you ever
    /// call this mid-session (e.g. after an error).

    func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        if #available(iOS 12.0, *) {
            configuration.environmentTexturing = .none
        }
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

    }
    
    // MARK: - Building the UI in code (no storyboard)
    
    var closeButton: UIButton!
    
    /// Because `loadView()` is overridden, UIKit will NOT load a .xib/storyboard
    /// for this view controller — this method is entirely responsible for
    /// creating `self.view` and everything in it.
    /// ViewController.swift
    override func loadView() {
        let customARView = VirtualObjectARView(frame: .zero)
        self.sceneView = customARView
        self.view = customARView

        let overlay = HandZoneOverlayView(frame: .zero)
        overlay.isHidden = true
        self.view.addSubview(overlay)
        self.handZoneOverlay = overlay

        statusLabel.textAlignment = .center
        statusLabel.textColor = .white
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        statusLabel.layer.cornerRadius = 8
        statusLabel.layer.masksToBounds = true
        statusLabel.text = "Ketuk layar untuk spawn hewan"
        self.view.addSubview(statusLabel)

        let spawnBtn = UIButton(type: .system)
        spawnBtn.setTitle("Spawn Food", for: .normal)
        spawnBtn.backgroundColor = .systemPurple
        spawnBtn.setTitleColor(.white, for: .normal)
        spawnBtn.layer.cornerRadius = 8
        spawnBtn.addTarget(self, action: #selector(didTapSpawnFood(_:)), for: .touchUpInside)
        self.view.addSubview(spawnBtn)
        self.spawnFoodButton = spawnBtn
        
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.contentHorizontalAlignment = .fill
        closeBtn.contentVerticalAlignment = .fill
        closeBtn.addTarget(self, action: #selector(didTapClose(_:)), for: .touchUpInside)
        self.view.addSubview(closeBtn)
        self.closeButton = closeBtn
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        handZoneOverlay.frame = view.bounds
        statusLabel.frame = CGRect(x: 20, y: 60, width: view.bounds.width - 40, height: 40)
        spawnFoodButton.frame = CGRect(x: 40, y: view.bounds.height - 100, width: 140, height: 40)
        closeButton.frame = CGRect(x: 20, y: 60, width: 44, height: 44)
    }
    
    @objc func didTapClose(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
