//
//  ContentView.swift
//  ARProject
//
//  Created by Ferdiansyah Annora on 13/07/26.
//

import SwiftUI
import RealityKit

struct ContentView : View {
    @StateObject private var manager = ARManager()
    @State private var scanPulse = false
    let animalModels = ["cat", "calf", "merak", "zebra"]
    
    @State private var panelState: PanelState = .hidden
    @State private var showGuideline: Bool = true
    
    var body: some View {
        ZStack {
            RealityView { content in
                let camAnchor = AnchorEntity(.camera)
                content.add(camAnchor)
                manager.cameraAnchor = camAnchor

                // Create horizontal plane anchor for the content
                let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
                
                // Add the horizontal plane anchor to the scene
                content.add(anchor)
                content.camera = .spatialTracking

                // Subscribe to anchor events to know when the plane is found
                let sub = content.subscribe(to: SceneEvents.AnchoredStateChanged.self) { event in
                    if event.isAnchored && event.anchor == anchor {
                        DispatchQueue.main.async {
                            if manager.isCoaching { // Only trigger the first time it anchors
                                withAnimation {
                                    manager.isCoaching = false
                                }
                                
                                // Create a static world anchor at the plane's current position so it never moves
                                let staticAnchor = AnchorEntity(world: anchor.transformMatrix(relativeTo: nil))
                                anchor.scene?.addAnchor(staticAnchor)
                                
                                manager.setup(cameraAnchor: camAnchor, planeAnchor: staticAnchor)
                            }
                        }
                    }
                }
                manager.eventSubscriptions.append(sub)
                
                let updateSub = content.subscribe(to: SceneEvents.Update.self) { _ in
                    manager.updateScene()
                }
                manager.eventSubscriptions.append(updateSub)
            }
            .onChange(of: manager.showFacts) { show in
                manager.toggleFacts(show: show)
            }
            .onChange(of: manager.isTooFar) { tooFar in
                if !tooFar && panelState == .hidden {
                    withAnimation {
                        panelState = .mainButtons
                    }
                }
            }
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { _ in
                        withAnimation {
                            showGuideline = false
                            if panelState == .hidden {
                                panelState = .mainButtons
                            } else {
                                panelState = .hidden
                            }
                        }
                    }
            )
            .edgesIgnoringSafeArea(.all)
            
            if manager.isCoaching {
                CoachingOverlayView()
                    .transition(.opacity)
                    .zIndex(1)
            } else if manager.isTooFar {
                VStack {
                    Text("Get closer to play! 🚶‍♂️")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.orange.opacity(0.85))
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .padding(.top, 50)
                    Spacer()
                }
                .transition(.opacity)
                .animation(.easeInOut, value: manager.isTooFar)
                .zIndex(2)
            }
            
            if !manager.isCoaching && !manager.isTooFar {
                DynamicPanelView(currentState: $panelState, manager: manager)
                    .zIndex(3)
                    .transition(.move(edge: .bottom))
            }

            if let event = manager.feedbackEvent, event.message != nil {
                VStack {
                    Spacer()
                    FeedbackToastView(event: event) {
                        withAnimation {
                            manager.feedbackEvent = nil
                        }
                    }
                    .padding(.bottom, 220)
                }
                .zIndex(4)
                .allowsHitTesting(false)
            }
        }
        .sensoryFeedback(trigger: manager.feedbackEvent) { _, newValue in
            guard let newValue else { return nil }
            switch newValue.haptic {
            case .success: return .success
            case .warning: return .warning
            case .light: return .selection
            }
        }
    }

}

//#Preview {
//    ContentView()
//}
