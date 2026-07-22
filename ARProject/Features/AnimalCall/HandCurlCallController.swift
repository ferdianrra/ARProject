import Vision
import Foundation

/// Detects a "curl / beckon" hand pose — fingers bent toward the palm, but
/// not a tight closed fist — as the call-the-animal trigger. Deliberately a
/// different pose from any pinch-style gesture, looking at all four
/// non-thumb fingertips together rather than thumb+index only.
///
/// A full fist isn't used on purpose: curling fingers all the way into the
/// palm can hide the fingertip landmarks from the camera, which lowers
/// Vision's tracking confidence for exactly the points this needs. A
/// partial curl keeps fingertips visible enough to track reliably.
///
/// Thresholds below are calibrated from real on-device readings (relaxed
/// open hand ~1.9, curled ~1.5) — re-tune against real hands if detection
/// feels off on a different device/lighting setup.
class HandCurlCallController {
    private let engageThreshold = 1.6  // relativeDistance below this -> curled
    private let releaseThreshold = 1.8 // relativeDistance above this -> open again

    /// ~1/3 second at a typical 30fps Vision cadence. Requiring a held pose
    /// (not just one lucky frame) avoids triggering on an incidental hand
    /// shape passing through on its way to something else.
    private let holdFramesRequired = 10
    private let lossToleranceFrames = 5

    private var isPoseCurled = false
    private var framesCurled = 0
    private var framesSinceGoodTracking = 0
    private var hasFiredForThisHold = false

    /// Feed this every frame from a hand observation. Returns true exactly
    /// once per held gesture — the frame the hold threshold is first
    /// crossed — not on every frame the pose stays curled, so call sites can
    /// treat a `true` result as a one-shot trigger. Firing resets only once
    /// the hand returns to open, so holding the curl doesn't call the animal
    /// repeatedly.
    func update(hand: VNHumanHandPoseObservation) -> Bool {
        guard
            let wrist = try? hand.recognizedPoint(.wrist),
            let indexTip = try? hand.recognizedPoint(.indexTip),
            let middleTip = try? hand.recognizedPoint(.middleTip),
            let ringTip = try? hand.recognizedPoint(.ringTip),
            let littleTip = try? hand.recognizedPoint(.littleTip),
            let middleMCP = try? hand.recognizedPoint(.middleMCP),
            wrist.confidence > 0.5, middleMCP.confidence > 0.5,
            indexTip.confidence > 0.3, middleTip.confidence > 0.3,
            ringTip.confidence > 0.3, littleTip.confidence > 0.3
        else {
            registerTrackingLost()
            return false
        }

        let handLength = hypot(wrist.location.x - middleMCP.location.x,
                                wrist.location.y - middleMCP.location.y)
        guard handLength > 0.01 else {
            registerTrackingLost()
            return false
        }

        // A relaxed open hand: fingertips sit far from the wrist. Curled:
        // they pull in noticeably closer. Averaging four fingertips (not
        // just one) makes this robust to any single fingertip's tracking
        // being briefly noisy.
        let tips = [indexTip, middleTip, ringTip, littleTip]
        let averageDistanceToWrist = tips.reduce(0.0) { partialSum, tip in
            partialSum + hypot(tip.location.x - wrist.location.x, tip.location.y - wrist.location.y)
        } / Double(tips.count)

        let relativeDistance = averageDistanceToWrist / handLength

        framesSinceGoodTracking = 0

        if isPoseCurled {
            if relativeDistance > releaseThreshold {
                isPoseCurled = false
                framesCurled = 0
                hasFiredForThisHold = false
            }
        } else if relativeDistance < engageThreshold {
            isPoseCurled = true
        }

        framesCurled = isPoseCurled ? framesCurled + 1 : 0

        if isPoseCurled && !hasFiredForThisHold && framesCurled >= holdFramesRequired {
            hasFiredForThisHold = true
            return true
        }

        return false
    }

    private func registerTrackingLost() {
        framesSinceGoodTracking += 1
        if framesSinceGoodTracking > lossToleranceFrames {
            isPoseCurled = false
            framesCurled = 0
            hasFiredForThisHold = false
        }
    }
}
