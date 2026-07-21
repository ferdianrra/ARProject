import SwiftUI

struct MainButtonsView: View {
    @Binding var currentState: PanelState
    @ObservedObject var manager: ARManager
    
    var body: some View {
        HStack(spacing: 15) {
            MainButton(
                title: "Life Cycle",
                imageName: "LifeCycle",
                buttonColor: Color(red: 0.88, green: 0.96, blue: 0.98),
                action: { currentState = .lifeCycleMode }
            )
            MainButton(
                title: "Feeding",
                imageName: "Feeding",
                buttonColor: Color(red: 0.98, green: 0.92, blue: 0.88),
                action: { currentState = .feedingMode }
            )
            MainButton(
                title: "Resize",
                imageName: "Resize",
                buttonColor: Color(red: 0.88, green: 0.93, blue: 0.98),
                action: { currentState = .resizeMode }
            )
            MainButton(
                title: "Facts",
                imageName: "Facts",
                buttonColor: Color(red: 0.98, green: 0.96, blue: 0.88),
                action: {
                    withAnimation {
                        manager.showFacts.toggle()
                    }
                }
            )
        }
        .padding(.vertical, 15)
    }
}

struct MainButton: View {
    let title: String
    let imageName: String
    let buttonColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Base white outer 3D plastic rim
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 6)
                        .frame(width: 108, height: 108)
                    
                    // Deep inner container slot
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(buttonColor)
                        .frame(width: 96, height: 96)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.6), lineWidth: 3)
                                .blur(radius: 1)
                                .offset(x: 1, y: 1)
                                .mask(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        )
                    
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)
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
        MainButton(title: "Life Cycle", imageName: "LifeCycle", buttonColor: Color(red: 0.88, green: 0.96, blue: 0.92)) {}
        MainButton(title: "Resize", imageName: "Resize", buttonColor: Color(red: 0.88, green: 0.96, blue: 0.92)) {}
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}

#Preview {
    let mockManager = ARManager()
    MainButtonsView(currentState: .constant(.lifeCycleMode), manager: mockManager)
}
