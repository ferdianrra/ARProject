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
            ARViewContainer(manager: manager)
                .ignoresSafeArea()
                .onChange(of: manager.showFacts) { show in
                    manager.toggleFacts(show: show)
                }
            .onChange(of: manager.isTooFar) { tooFar in
                if tooFar {
                    withAnimation {
                        panelState = .mainButtons
                    }
                } else if !tooFar && panelState == .hidden {
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
            // OLD — onTapGesture has no location, so PlacementController had to use
            // camera math (forward vector projection) instead of a real raycast.
            // .onTapGesture {
            //     if !manager.isPlaced && !manager.isCoaching {
            //         manager.handleTap()   // no screen location = math-based, not best practice
            //     }
            // }

            // BEST PRACTICE — DragGesture(minimumDistance: 0) fires instantly on any touch
            // and provides value.startLocation: the exact CGPoint where the finger landed.
            // This is passed to handleTap(at:) → PlacementController → arView.raycast(from: point)
            // so placement only succeeds when the tap actually hits a real ARKit floor plane.
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        if !manager.isPlaced && !manager.isCoaching && manager.isFloorTargeted {
                            manager.handleTap(at: value.startLocation)
                        }
                    }
            )
            .edgesIgnoringSafeArea(.all)
            
            // 4 portals + label: only shown when camera is actively targeting a valid floor
            if !manager.isPlaced && !manager.isCoaching && manager.isFloorTargeted {
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
            
            // Guidance label: shown after coaching but before floor is targeted
            // Tells user to point camera at the floor instead of letting them tap blindly
            if !manager.isPlaced && !manager.isCoaching && !manager.isFloorTargeted {
                VStack {
                    Spacer()
                    Text("Point camera at the floor")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(20)
                    Spacer()
                }
                .transition(.opacity)
                .zIndex(5)
            }
            
            if manager.isCoaching {
                CoachingOverlayView()
                    .transition(.opacity)
                    .zIndex(1)
            } else if manager.isPlaced && !manager.isFeedingActive {
                if manager.isLockedNearActive {
                    VStack(spacing: 12) {
                        InformationContainer(
                            message: "Coming soon! New habitat unlocking in future updates.",
                            isWarning: false,
                            showButton: false,
                            alignment: .top
                        )
                    }
                    .padding(.top, 48)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .transition(.opacity)
                    .animation(.easeInOut, value: manager.isLockedNearActive)
                    .zIndex(2)
                } else if manager.isTooFar {
                    VStack(spacing: 12) {
                        InformationContainer(
                            message: "Get closer to play!",
                            isWarning: true,
                            showButton: false,
                            alignment: .top
                        )
                    }
                    .padding(.top, 48)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .transition(.opacity)
                    .animation(.easeInOut, value: manager.isTooFar)
                    .zIndex(2)
                } else {
                    VStack(spacing: 12) {
                        InformationContainer(
                            message: topInstructionText(for: panelState),
                            isWarning: false,
                            showButton: false,
                            alignment: .top
                        )
                        
                        if panelState == .lifeCycleMode {
                            Text(lifeCyclePhaseMessage(for: manager.currentLifeCyclePhase))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(red: 0.15, green: 0.70, blue: 0.35), in: Capsule())
                                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .animation(.spring(), value: manager.currentLifeCyclePhase)
                        }
                    }
                    .padding(.top, 48)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .animation(.easeInOut(duration: 0.3), value: panelState)
                    .transition(.opacity)
                    .animation(.easeInOut, value: manager.isTooFar)
                    .zIndex(2)
                }
            }
            
            if !manager.isCoaching && manager.isPlaced && !manager.isTooFar && !manager.isFeedingActive {
                DynamicPanelView(currentState: $panelState, manager: manager)
                    .zIndex(3)
                    .transition(.move(edge: .bottom))
            }
            
            if manager.isPlaced && !manager.isCoaching && !manager.isFeedingActive {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                manager.resetPlacement()
                                panelState = .hidden
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Reset Area")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.6), in: Capsule())
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 48)
                    }
                    Spacer()
                }
                .zIndex(7)
                .transition(.opacity)
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
            }
            
            if manager.showFactSheet, let spot = manager.currentFactSpot {
                ButterflyFactSheetView(
                    isPresented: $manager.showFactSheet,
                    isQuestionActive: $manager.isFactQuestionActive,
                    onDecision: { decision in
                        manager.handleFactDecision(decision, spot: spot)
                    }
                )
                .environmentObject(manager)
                .zIndex(6)
                .transition(.opacity)
            }

            if let event = manager.feedbackEvent, event.message != nil {
                VStack {
                    FeedbackToastView(event: event) {
                        withAnimation {
                            manager.feedbackEvent = nil
                        }
                    }
                    .padding(.top, 50)
                    Spacer()
                }
                .zIndex(10)
            }
        }
    }

    private func topInstructionText(for state: PanelState) -> String {
        switch state {
        case .lifeCycleMode:
            return "Slide the bar to see animal phases! The animal is in the center of the habitat."
        case .resizeMode:
            return "Drag slider to adjust animal size!"
        case .feedingMode:
            return "Hold out your hand to feed the butterfly!"
        default:
            return "Explore the animal! Walk out of the arena to exit."
        }
    }
    
    private func lifeCyclePhaseMessage(for phase: Int) -> String {
        switch phase {
        case 1: return "Look, a tiny egg!"
        case 2: return "It hatched into a caterpillar!"
        case 3: return "It's forming a chrysalis..."
        default: return "All grown up into a butterfly!"
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
