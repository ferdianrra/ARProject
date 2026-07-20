// MARK: - Feeding integration extension
import Foundation

extension ARManager {
    /// Wrapper that forwards to the feeding controller.
    func startFeedingMode() {
        feedingController.startFeeding()
    }

    /// Wrapper that forwards to the feeding controller.
    func stopFeedingMode() {
        feedingController.stopFeeding()
    }

    /// Called each frame when feeding is active.
    func updateFeedingIfNeeded() {
        feedingController.update(cameraAnchor: cameraAnchor)
    }
}
