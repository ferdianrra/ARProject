//
//  ButtonPanelView.swift
//  ARProject
//

import SwiftUI

enum PanelState {
    case hidden
    case mainButtons
    case resizeMode
    case lifeCycleMode
    case feedingMode
}

struct DynamicPanelView: View {
    @Binding var currentState: PanelState
    @ObservedObject var manager: ARManager
    
    @State private var scale: Float = 1.0
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                switch currentState {
                case .hidden:
                    EmptyView()
                    
                case .mainButtons:
                    MainButtonsView(currentState: $currentState, manager: manager)
                    
                case .resizeMode:
                    ResizeModeView(currentState: $currentState, manager: manager)
                    
                case .lifeCycleMode:
                    LifeCycleModeView(currentState: $currentState, manager: manager)
                    
                case .feedingMode:
                    LifeCycleModeView(currentState: $currentState, manager: manager)
                }
            }
            .padding(.horizontal, 20)
            .background(
                Group {
                    if currentState != .hidden {
                        RoundedRectangle(cornerRadius: 35, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 35, style: .continuous)
                                    .fill(Color.white.opacity(0.2))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 35, style: .continuous)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 3)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                }
            )
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0), value: currentState)
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        DynamicPanelView(currentState: .constant(.mainButtons), manager: ARManager())
    }
}
