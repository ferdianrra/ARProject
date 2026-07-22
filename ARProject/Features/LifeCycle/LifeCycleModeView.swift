import SwiftUI

struct LifeCycleModeView: View {
    @Binding var currentState: PanelState
    @ObservedObject var manager: ARManager
    @State private var lifeCyclePhase: Double = 1.0
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: { currentState = .mainButtons }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.red.opacity(0.9))
            }
            
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
                        let intPhase = Int(phase)
                        manager.currentLifeCyclePhase = intPhase
                        manager.lifeCycleController.changePhase(to: intPhase, manager: manager)
                    }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .onAppear {
            let intPhase = Int(lifeCyclePhase)
            manager.currentLifeCyclePhase = intPhase
            manager.lifeCycleController.changePhase(to: intPhase, manager: manager)
        }
        .onDisappear {
            manager.lifeCycleController.exitLifeCycle(manager: manager)
        }
    }
}
