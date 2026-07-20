import SwiftUI

struct MainButtonsView: View {
    @Binding var currentState: PanelState
    @ObservedObject var manager: ARManager
    
    var body: some View {
        HStack(spacing: 15) {
            MainButton(imageName: "LifeCycle", buttonColor: Color(red: 0.88, green: 0.96, blue: 0.98),
                       action: { currentState = .lifeCycleMode})
            MainButton(imageName: "Feeding", buttonColor: Color(red: 0.98, green: 0.92, blue: 0.88), action: { currentState = .feedingMode })
            MainButton(imageName: "Resize", buttonColor: Color(red: 0.88, green: 0.93, blue: 0.98), action: { currentState = .resizeMode })
            MainButton(imageName: "Facts", buttonColor: Color(red: 0.98, green: 0.96, blue: 0.88), action: {
                withAnimation {
                    manager.showFacts.toggle()
                }
            })
            }
        .padding(.vertical, 15)
    }
}

import SwiftUI

struct MainButton: View {
    let imageName: String
    let buttonColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Base white outer 3D plastic rim
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 6)
                    .frame(width: 132, height: 132)
                
                // Deep inner container slot
                RoundedRectangle(cornerRadius: 22, style: .continuous)
//                    .fill(Color(red: 0.96, green: 0.95, blue: 0.92))
                    .fill(buttonColor)
                    .frame(width: 120, height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 3)
                            .blur(radius: 1)
                            .offset(x: 1, y: 1)
                            .mask(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    )
//                Image("Feed")
                Image(imageName)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(ToyCardPressStyle())
    }
}

struct ToyCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview("3D Control Buttons") {
    HStack(spacing: 20) {
        MainButton(imageName: "leaf.fill", buttonColor: Color(red: 0.88, green: 0.96, blue: 0.92)) {}
        MainButton(imageName: "leaf.fill", buttonColor: Color(red: 0.88, green: 0.96, blue: 0.92)) {}
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}


#Preview() {
    let mockManager = ARManager()
    
    MainButtonsView(currentState: .constant(.lifeCycleMode), manager: mockManager)
}

