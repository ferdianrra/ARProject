//
//  HandZoneOverlayView.swift
//  ARProject
//
//  Created by Nadia Putri Natali Lubis on 14/07/26.
//
//  Draws two diagonal yellow "arms" that visually converge at the center of the screen, forming a V-shape hinting where the player should aim to pick up / feed. Pure UIKit drawing (CALayer transforms), no AR content — this view just overlays the AR camera feed. No unused code found in this file.
//

import UIKit

class HandZoneOverlayView: UIView {
    private let leftHand = UIImageView()
    private let rightHand = UIImageView()
    
    enum HandState {
        case reaching
        case grabbing
    }
    
    /// Call this from `FeedingController` whenever the catch state changes — e.g. `overlay.state = .grabbing` when food is picked up, and `.reaching` once it's released/reset.
    var state: HandState = .reaching {
        didSet {
            guard oldValue != state else { return }
            updateImages(for: state)
            setNeedsLayout()
        }
    }
    
    /// The target zone at the center of the screen where food needs to be aimed.
    var zoneRect: CGRect {
        let size: CGFloat = 180
        return CGRect(x: bounds.midX - size / 2, y: bounds.midY - size / 2, width: size, height: size)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        leftHand.image = UIImage(named: "reach-lefthand")
        rightHand.image = UIImage(named: "reach-righthand")

        [leftHand, rightHand].forEach {
            $0.contentMode = .scaleAspectFit
            $0.clipsToBounds = true
            addSubview($0)
        }

        // Debug only — uncomment to visualize each hand's actual bounding box
//         leftHand.backgroundColor = .red.withAlphaComponent(0.3)
//         rightHand.backgroundColor = .blue.withAlphaComponent(0.3)

        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func updateImages(for state: HandState) {
        switch state {
        case .reaching:
            leftHand.image = UIImage(named: "reach-lefthand")
            rightHand.image = UIImage(named: "reach-righthand")
        case .grabbing:
            leftHand.image = UIImage(named: "grab-lefthand")
            rightHand.image = UIImage(named: "grab-righthand")
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }

        // Fixed hand size — proportional to screen width, not distance-based
        let handWidth = bounds.width * 0.32
        
        switch state {
        case .reaching:
//            let leftAnchor = CGPoint(x: bounds.minX + handWidth * 0.35, y: bounds.maxY + 100)
//            let rightAnchor = CGPoint(x: bounds.maxX - handWidth * 0.35, y: bounds.maxY + 100)
//            configureHand(leftHand, targetWidth: handWidth, anchorPoint: leftAnchor, rotation: 25 * .pi / 180)
//            configureHand(rightHand, targetWidth: handWidth, anchorPoint: rightAnchor, rotation: -25 * .pi / 180)
            
            let leftAnchor = CGPoint(x: bounds.minX + handWidth * 0.35, y: bounds.maxY + 100)
            let rightAnchor = CGPoint(x: bounds.maxX - handWidth * 0.35, y: bounds.maxY + 100)

            configureHand(leftHand, targetWidth: handWidth, anchorPoint: leftAnchor, rotation: 25 * .pi / 180)
            configureHand(rightHand, targetWidth: handWidth, anchorPoint: rightAnchor, rotation: -25 * .pi / 180)
            
        case .grabbing:
            // Hands move up and inward toward the zoneRect, and stand more upright
            let leftAnchor = CGPoint(x: bounds.midX - handWidth , y: bounds.midY + handWidth * 1.7)
            let rightAnchor = CGPoint(x: bounds.midX + handWidth , y: bounds.midY + handWidth * 1.7)
            configureHand(leftHand, targetWidth: handWidth, anchorPoint: leftAnchor, rotation: 15 * .pi / 180)
            configureHand(rightHand, targetWidth: handWidth, anchorPoint: rightAnchor, rotation: -15 * .pi / 180)
        }
    }

    /// Positions a fixed-size hand image so its WRIST (bottom-center of the
    /// image) sits at `anchorPoint`, then tilts it by `rotation` so the
    /// fingers angle up and inward toward the center of the screen.
    ///
    /// The height is derived from the image's real aspect ratio (not a
    /// guessed multiplier), so the view's bounds always match the visible
    /// pixels — no leftover transparent margin.
    private func configureHand(_ hand: UIImageView, targetWidth: CGFloat, anchorPoint: CGPoint, rotation: CGFloat) {
        let aspectRatio: CGFloat
        if let image = hand.image, image.size.width > 0 {
            aspectRatio = image.size.height / image.size.width
        } else {
            aspectRatio = 1.35 // fallback if image failed to load
        }

        let size = CGSize(width: targetWidth, height: targetWidth * aspectRatio)

        hand.bounds = CGRect(origin: .zero, size: size)
        hand.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0) // bottom-center = wrist
        hand.layer.position = anchorPoint
        hand.layer.transform = CATransform3DMakeRotation(rotation, 0, 0, 1)
        
        UIView.animate(withDuration: 0.2) {
                    hand.bounds = CGRect(origin: .zero, size: size)
                    hand.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0) // bottom-center = wrist
                    hand.layer.position = anchorPoint
                    hand.layer.transform = CATransform3DMakeRotation(rotation, 0, 0, 1)
                }
    }
}

#Preview("iPad Pro 11\" - Landscape") {
    // 11-inch iPad Pro landscape dimensions (1210 x 834 points)
    let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1210, height: 834))
    containerView.backgroundColor = .darkGray

    let overlay = HandZoneOverlayView(frame: containerView.bounds)
    overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    containerView.addSubview(overlay)
    return containerView
}

#Preview("Reaching - iPad Pro 11\" Landscape") {
    let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1210, height: 834))
    containerView.backgroundColor = .darkGray

    let overlay = HandZoneOverlayView(frame: containerView.bounds)
    overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    overlay.state = .reaching

    containerView.addSubview(overlay)
    return containerView
}

#Preview("Grabbing - iPad Pro 11\" Landscape") {
    let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1210, height: 834))
    containerView.backgroundColor = .darkGray

    let overlay = HandZoneOverlayView(frame: containerView.bounds)
    overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    overlay.state = .grabbing

    containerView.addSubview(overlay)
    return containerView
}
