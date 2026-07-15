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
            
            Slider(value: $lifeCyclePhase, in: 1...4, step: 1)
                .accentColor(.blue)
                .onChange(of: lifeCyclePhase) { phase in
                    manager.changePhase(to: Int(phase))
                }
            
            Text("🦋")
                .font(.system(size: 24))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 25)
    }
}
