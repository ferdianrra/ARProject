// MARK: - Placement integration extension
import Foundation
import CoreGraphics

extension ARManager {
    /// Legacy path — kept intact so nothing breaks if called without a tap location.
    func handleTap() {
        placementController.handleTap()
    }

    /// Best-practice path — called with the exact screen-space tap point.
    /// PlacementController will raycast from this point to find a real floor plane.
    func handleTap(at point: CGPoint) {
        placementController.handleTap(at: point)
    }
}
