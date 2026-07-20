// MARK: - Placement integration extension
import Foundation

extension ARManager {
    /// Wrapper that forwards to the placement controller.
    func handleTap() {
        placementController.handleTap()
    }
}
