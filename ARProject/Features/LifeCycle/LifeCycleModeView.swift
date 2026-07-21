import SwiftUI

struct LifeCycleModeView: View {
    @Binding var currentState: PanelState
    @ObservedObject var manager: ARManager
    @State private var lifeCyclePhase: Double = 4.0
    
    var body: some View {
        VStack(spacing: 12) {
            // Floating Phase Description Pill directly above slider sheet
            HStack(spacing: 8) {
                Text(phaseMessage(for: Int(lifeCyclePhase)))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.9))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            }
            .animation(.easeInOut, value: lifeCyclePhase)
            
            HStack(spacing: 20) {
                Button(action: { currentState = .mainButtons }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.red.opacity(0.9))
                }
                
                Text("🥚")
                    .font(.system(size: 24))
                
                ZStack {
                    HStack {
                        ForEach(1..<5) { step in
                            VStack {
                                Rectangle()
                                    .fill(Color.white.opacity(0.5))
                                    .frame(width: 2, height: 10)
                                Text("\(step)")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            if step < 4 {
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    
                    Slider(value: $lifeCyclePhase, in: 1...4, step: 1)
                        .tint(.blue)
                        .onChange(of: lifeCyclePhase) { _, phase in
                            manager.lifeCycleController.changePhase(to: Int(phase), manager: manager)
                        }
                }
                
                Text("🦋")
                    .font(.system(size: 24))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .onAppear {
            manager.lifeCycleController.changePhase(to: Int(lifeCyclePhase), manager: manager)
        }
        .onDisappear {
            manager.lifeCycleController.exitLifeCycle(manager: manager)
        }
    }

    private func phaseMessage(for phase: Int) -> String {
        switch phase {
        case 1: return "Look, a tiny egg!"
        case 2: return "It hatched into a caterpillar!"
        case 3: return "It's forming a chrysalis..."
        default: return "All grown up into a butterfly!"
        }
    }
}
