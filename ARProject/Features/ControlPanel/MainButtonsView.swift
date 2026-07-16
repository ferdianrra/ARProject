import SwiftUI

struct MainButtonsView: View {
    @Binding var currentState: PanelState
    @ObservedObject var manager: ARManager
    
    var body: some View {
        HStack(spacing: 15) {
            Button(action: { currentState = .lifeCycleMode }) {
                VStack {
                    Text("🦋")
                        .font(.system(size: 28))
                    Text("Phase")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                }
                .frame(width: 75, height: 75)
                .background(Color.blue.opacity(0.85))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    
            }
            
            Button(action: { currentState = .feedMode }) {
                VStack {
                    Text("🍃")
                        .font(.system(size: 28))
                    Text("Feed")
                        .font(.system(size: 14, weight: .heavy))
                }
                .frame(width: 75, height: 75)
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            }
            
            Button(action: { currentState = .resizeMode }) {
                VStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 28, weight: .bold))
                    Text("Size")
                        .font(.system(size: 14, weight: .heavy))
                }
                .frame(width: 75, height: 75)
                .background(Color.orange.opacity(0.85))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            
            Button(action: {
                withAnimation {
                    manager.showFacts.toggle()
                }
                manager.triggerFeedback(tone: .positive, haptic: .light)
            }) {
                VStack {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 28, weight: .bold))
                    Text("Facts")
                        .font(.system(size: 14, weight: .heavy))
                }
                .frame(width: 75, height: 75)
                .background(manager.showFacts ? Color.purple.opacity(0.9) : Color.purple.opacity(0.5))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(.vertical, 15)
    }
}
