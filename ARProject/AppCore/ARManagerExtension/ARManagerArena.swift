// MARK: - Arena integration extension
import Foundation
import RealityKit

extension ARManager {
    /// Wrapper that forwards to the arena controller.
    func updateScene() {
        guard let camAnchor = cameraAnchor,
              let anchor = anchorRef else { return }

        guard anchor.isAnchored else {
            self.distanceText = "Scanning surrounding area..."
            return
        }
        
        arenaController.checkProximity()
    }
}
