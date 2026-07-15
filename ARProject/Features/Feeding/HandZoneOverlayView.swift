//
//  HandZoneOverlayView.swift
//  ARProject
//
//  Created by Nadia Putri Natali Lubis on 14/07/26.
//
//  Draws two diagonal yellow "arms" that visually converge at the center of
//  the screen, forming a V-shape hinting where the player should aim to pick
//  up / feed. Pure UIKit drawing (CALayer transforms), no AR content — this
//  view just overlays the AR camera feed. No unused code found in this file.
//

import UIKit

class HandZoneOverlayView: UIView {
    private let leftHand = UIView()
    private let rightHand = UIView()

    /// The target zone at the center of the screen where food needs to be
    /// aimed. `ViewController+Feeding.swift` checks whether a food node's
    /// projected 2D screen position falls inside this rect to decide whether
    /// the player is "aiming correctly."
    var zoneRect: CGRect {
        let size: CGFloat = 180
        return CGRect(x: bounds.midX - size / 2, y: bounds.midY - size / 2, width: size, height: size)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        [leftHand, rightHand].forEach {
            $0.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.85)
            $0.layer.cornerRadius = 14
            addSubview($0)
        }
        // This overlay is purely visual — don't let it intercept touches
        // meant for the AR view underneath (e.g. the tap-to-place gesture).
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let thickness: CGFloat = max(36, bounds.width * 0.05)

        // Each "arm" stretches from screen center out to near a bottom corner.
        let bottomLeft = CGPoint(x: bounds.minX + 20, y: bounds.maxY - 40)
        let bottomRight = CGPoint(x: bounds.maxX - 20, y: bounds.maxY - 40)

        configureArm(leftHand, from: center, to: bottomLeft, thickness: thickness)
        configureArm(rightHand, from: center, to: bottomRight, thickness: thickness)
    }

    /// Positions one "arm" so that one end sits exactly at `pivot` (screen
    /// center), then stretches out toward `farPoint`.
    ///
    /// The trick: setting `anchorPoint` to (0, 0.5) makes the LEFT-CENTER
    /// edge of the layer the rotation/position anchor, instead of the
    /// default center. That lets us place that anchor exactly at `pivot` via
    /// `layer.position`, then rotate the whole bar around it — which is what
    /// guarantees both arms always meet exactly at screen center, regardless
    /// of screen size. `atan2(dy, dx)` gives the angle from pivot to
    /// farPoint, and `sqrt(dx*dx + dy*dy)` (Pythagorean theorem) gives the
    /// straight-line distance, which becomes the bar's length.
    private func configureArm(_ arm: UIView, from pivot: CGPoint, to farPoint: CGPoint, thickness: CGFloat) {
        let dx = farPoint.x - pivot.x
        let dy = farPoint.y - pivot.y
        let length = sqrt(dx * dx + dy * dy)
        let angle = atan2(dy, dx)

        arm.bounds = CGRect(x: 0, y: 0, width: length, height: thickness)
        arm.layer.anchorPoint = CGPoint(x: 0, y: 0.5) // anchor at the bar's left edge, vertically centered
        arm.layer.position = pivot                     // pin that anchor to screen center
        arm.layer.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
    }
}
