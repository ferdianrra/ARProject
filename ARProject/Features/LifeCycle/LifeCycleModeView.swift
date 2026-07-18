import SwiftUI

struct LifeCycleModeView: View {
    @Binding var currentState: PanelState
    @ObservedObject var manager: ARManager
    @State private var lifeCyclePhase: Double = 4.0
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: { currentState = .mainButtons }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.red.opacity(0.9))
            }
            
            Text("🥚")
                .font(.system(size: 24))
            
            ZStack {
                // Tick marks and lines behind the slider
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
                        manager.triggerFeedback(message: phaseMessage(for: Int(phase)), tone: .positive, haptic: .light)
                    }
            }
            
            Text("🦋")
                .font(.system(size: 24))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 25)
        .onAppear {
            // Automatically spawn the idle butterfly (Phase 4) when entering this mode
            manager.lifeCycleController.changePhase(to: Int(lifeCyclePhase), manager: manager)
        }
        .onDisappear {
            manager.lifeCycleController.exitLifeCycle(manager: manager)
        }
    }

    private func phaseMessage(for phase: Int) -> String {
        switch phase {
        case 1: return "🥚 It's an egg!"
        case 2: return "🐛 It's a caterpillar now!"
        case 3: return "🛖 It's forming a chrysalis!"
        default: return "🦋 It's a butterfly!"
        }
    }
}
