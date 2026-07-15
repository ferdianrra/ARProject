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
                    .accentColor(.blue)
                    .onChange(of: lifeCyclePhase) { phase in
                        manager.lifeCycleController.changePhase(to: Int(phase), manager: manager)
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
}
