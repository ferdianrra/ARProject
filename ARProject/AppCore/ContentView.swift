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
    @State private var trackingSession = SpatialTrackingSession()
    
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
                
                let configuration = SpatialTrackingSession.Configuration(
                    tracking: [.plane],
                    sceneUnderstanding: [.occlusion, .physics, .collision, .shadow],
                    camera: .back
                )
                Task {
                    await trackingSession.run(configuration)
                }

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
            .onTapGesture {
                if !manager.isPlaced && !manager.isCoaching {
                    manager.handleTap()
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            if !manager.isPlaced && !manager.isCoaching {
                VStack {
                    Spacer()
                    ZStack {
                        Rectangle()
                            .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [5, 5]))
                            .foregroundColor(.orange.opacity(0.8))
                            .frame(width: 150, height: 150)
                        
                        VStack {
                            HStack {
                                CircleGuideView()
                                Spacer()
                                CircleGuideView()
                            }
                            Spacer()
                            HStack {
                                CircleGuideView()
                                Spacer()
                                CircleGuideView()
                            }
                        }
                        .frame(width: 170, height: 170)
                    }
                    .frame(width: 180, height: 180)
                    
                    Text("Tap screen to place the area")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(20)
                        .padding(.top, 30)
                    
                    Spacer()
                }
                .transition(.opacity)
                .zIndex(5)
            }
            
            if manager.isCoaching {
                CoachingOverlayView()
                    .transition(.opacity)
                    .zIndex(1)
            } else if manager.isTooFar && manager.isPlaced {
                VStack {
                    Text("Get closer to play!")
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
            
            if !manager.isCoaching && (!manager.isTooFar || !manager.isPlaced) && !manager.isFeedingActive {
                DynamicPanelView(currentState: $panelState, manager: manager)
                    .zIndex(3)
                    .transition(.move(edge: .bottom))
            }
            
            if manager.isFeedingActive {
                HandZoneOverlayRepresentable(state: manager.feedingOverlayState)
                    .allowsHitTesting(false)
                    .edgesIgnoringSafeArea(.all)
                    .zIndex(4)
                
                VStack {
                    HStack {
                        Button(action: {
                            manager.stopFeedingMode()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .padding(.leading, 20)
                        .padding(.top, 24)
                        
                        Spacer()
                    }
                    Spacer()
                }
                .zIndex(5)
            }
        }
        .onChange(of: panelState) { oldVal, newVal in
            if newVal == .feedMode {
                manager.startFeedingMode()
                panelState = .mainButtons
            }
        }
    }
}

struct CircleGuideView: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.orange, lineWidth: 2)
                .background(Circle().fill(Color.orange.opacity(0.2)))
                .frame(width: 40, height: 40)
            Text("?")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

//#Preview {
//    ContentView()
//}
