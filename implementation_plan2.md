# Implementation Plan: Feeding Feature Port (Iteration 1)

The goal is to transform the feeding feature from the `RecognizingAndLabelingArbitraryObjects` repo into the `ARProject`. 

For this first iteration, we will focus strictly on successfully porting the UI, logic, and connectivity, without applying advanced performance fixes just yet.

---

## 1. UI & Navigation (The Connector)
- **Main Connector:** Update `MainButtonsView.swift` and `ButtonPanelView.swift` so that when the "Feeding" button is tapped, it correctly routes the user to the new `FeedingModeView` (replacing the hardcoded `LifeCycleModeView` bug).
- **FeedingModeView:** Create this new view to look like the other feature panels. It will include:
  - An `xmark.circle.fill` button to gracefully exit feeding mode.
  - Text instructions indicating the current state ("Pinch the flower to feed!").
  - The **colored sphere guide** overlay ported from the old repo, which will change colors dynamically based on the user's hand distance and hover state.

## 2. Framework Imports
- **Critical Requirement:** Ensure all new and modified Swift files (especially `ARManagerFeeding.swift` and `FeedingController.swift`) have the necessary framework imports at the top:
  - `import RealityKit`
  - `import ARKit`
  - `import Vision`
  - `import SwiftUI` (for any view integrations)
  This will prevent the compiler errors we saw previously where `Entity` and `position(relativeTo:)` were unrecognized.

## 3. Core Feeding Logic Port
- **Feeding Controller:** Create `FeedingController.swift` to handle:
  - Spawning the food pillars (3 pillars, 2/3 camera height, clamped to the 1.5m arena).
  - Processing hand gestures to drag the food.
  - Enforcing the 1.5-meter boundary logic.
- **Butterfly Flight:** Implement the smooth `butterfly.look(at:)` flight logic so the butterfly turns and chases the food.

---

## 🚧 Phase 2 Suggestions (Not in Iteration 1)
As discussed, we will keep the following known bugs/optimizations in mind for a future iteration, but **will not implement them in this first pass**:
1. **The ISP Resource Crash:** Dynamically turning off `.mesh` and toggling `.sceneDepth` to save LiDAR bandwidth.
2. **Vision Buffer Deadlock:** Using a CoreVideo `deepCopy()` to prevent Vision from hoarding ARKit's 12-frame limit.
3. **RealityKit Memory Leak:** Fixing the `SceneEvents.Update` closure retain cycle with `[weak manager]`.

---

## User Review Required

> [!IMPORTANT]
> **Final Approval**
> The plan has been updated to focus strictly on porting the feature, UI connectors, and framework imports, while moving the heavy performance fixes to a "Suggestion" phase for later. 
> If this updated roadmap looks correct, hit **Proceed**!
