// MARK: - Facts & Decision integration extension
import Foundation
import RealityKit
import ARKit
import QuartzCore

extension ARManager {
    /// Connects HeadGestureController callbacks to handle smile/frown automatically.
    func setupHeadGestureListener() {
        headGestureController.onGesture = { [weak self] gesture in
            guard let self = self, self.showFactSheet, let spot = self.currentFactSpot else { return }
            let decision: HeadDecision = (gesture == .smile) ? .accepted : .rejected
            self.handleFactDecision(decision, spot: spot)
        }
    }

    /// No-op per-frame method maintained for compatibility with ArenaController.
    func processFaceGestureIfNeeded() {}

    /// Handles the user's decision (accepted/rejected) from facts sheet or facial expressions.
    func handleFactDecision(_ decision: HeadDecision, spot: ARSpot) {
        DispatchQueue.main.async {
            self.showFactSheet = false
            self.isFactQuestionActive = false
        }
        guard decision != .none else { return }
        
        let emoji = (decision == .accepted) ? "😆" : "☹️"
        factController.spawnEmoji(emoji: emoji, at: spot)
        
        if decision == .accepted {
            triggerFeedback(
                message: "Yay! You became friends with the butterfly! 😆",
                tone: .positive,
                haptic: .success,
                sound: .positiveChime
            )
        } else {
            triggerFeedback(
                message: "The butterfly is sad you declined... ☹️",
                tone: .negative,
                haptic: .warning,
                sound: .negativeBuzz
            )
        }
    }
}
