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
            } else if manager.isPlaced && !manager.isFeedingActive {
                if manager.isTooFar {
                    InformationContainer(
                        message: "Get closer to play!",
                        isWarning: true,
                        showButton: false,
                        alignment: .top
                    )
                    .transition(.opacity)
                    .animation(.easeInOut, value: manager.isTooFar)
                    .zIndex(2)
                } else {
                    InformationContainer(
                        message: topInstructionText(for: panelState),
                        isWarning: false,
                        showButton: false,
                        alignment: .top
                    )
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
