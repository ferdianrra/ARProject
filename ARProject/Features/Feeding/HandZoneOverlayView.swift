//
//  HandZoneOverlayView.swift
//  ARProject
//
//  Created by Nadia Putri Natali Lubis on 14/07/26.
//

//
//  HandZoneOverlayView.swift
//  ARProject
//

import UIKit

class HandZoneOverlayView: UIView {
    private let leftHand = UIView()
    private let rightHand = UIView()

    /// Area target di tengah layar, tempat makanan harus diarahkan.
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
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let thickness: CGFloat = max(36, bounds.width * 0.05)

        // Ujung lengan ditarik hampir ke pojok bawah layar
        let bottomLeft = CGPoint(x: bounds.minX + 20, y: bounds.maxY - 40)
        let bottomRight = CGPoint(x: bounds.maxX - 20, y: bounds.maxY - 40)

        configureArm(leftHand, from: center, to: bottomLeft, thickness: thickness)
        configureArm(rightHand, from: center, to: bottomRight, thickness: thickness)
    }

    /// Menempatkan satu "lengan" agar salah satu ujungnya persis di `pivot` (titik tengah layar),
    /// lalu memanjang keluar ke arah `farPoint`. Ini yang bikin titik temu kedua lengan selalu
    /// pas di tengah layar, berapa pun ukuran layarnya.
    private func configureArm(_ arm: UIView, from pivot: CGPoint, to farPoint: CGPoint, thickness: CGFloat) {
        let dx = farPoint.x - pivot.x
        let dy = farPoint.y - pivot.y
        let length = sqrt(dx * dx + dy * dy)
        let angle = atan2(dy, dx)

        arm.bounds = CGRect(x: 0, y: 0, width: length, height: thickness)
        arm.layer.anchorPoint = CGPoint(x: 0, y: 0.5) // pivot di ujung kiri bar
        arm.layer.position = pivot                     // taruh pivot itu tepat di titik tengah layar
        arm.layer.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
    }
}
