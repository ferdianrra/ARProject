import ARKit
import QuartzCore

enum HeadGesture {
    case smile
    case frown
}

final class HeadGestureController {

    private let cooldown: TimeInterval = 1.2
    private var lastGestureTime: TimeInterval = 0

    var onGesture: ((HeadGesture) -> Void)?

    func reset() {
        lastGestureTime = CACurrentMediaTime()
    }

    func update(faceAnchor: ARFaceAnchor, timestamp: TimeInterval) {
        guard timestamp - lastGestureTime > cooldown else { return }

        let blendShapes = faceAnchor.blendShapes

        let smileLeft = blendShapes[.mouthSmileLeft]?.floatValue ?? 0
        let smileRight = blendShapes[.mouthSmileRight]?.floatValue ?? 0
        let smileScore = (smileLeft + smileRight) / 2.0

        let frownLeft = blendShapes[.mouthFrownLeft]?.floatValue ?? 0
        let frownRight = blendShapes[.mouthFrownRight]?.floatValue ?? 0
        let frownScore = (frownLeft + frownRight) / 2.0

        let sneerLeft = blendShapes[.noseSneerLeft]?.floatValue ?? 0
        let sneerRight = blendShapes[.noseSneerRight]?.floatValue ?? 0
        let sneerScore = (sneerLeft + sneerRight) / 2.0

        let puckerScore = blendShapes[.mouthPucker]?.floatValue ?? 0

        let totalFrownScore = max(frownScore, sneerScore, puckerScore)

        if smileScore > 0.38 {
            print("🎯 [HeadGestureController] EXPRESSION DETECTED: smile 😆 (score: \(smileScore))")
            lastGestureTime = timestamp
            onGesture?(.smile)
            return
        }

        if totalFrownScore > 0.35 {
            print("🎯 [HeadGestureController] EXPRESSION DETECTED: frown ☹️ (score: \(totalFrownScore))")
            lastGestureTime = timestamp
            onGesture?(.frown)
            return
        }
    }
}
3
