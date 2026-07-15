import SwiftUI

struct ResizeModeView: View {
    @Binding var currentState: PanelState
    @ObservedObject var manager: ARManager
    @State private var scale: Float = 1.0
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: { currentState = .mainButtons }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.red.opacity(0.9))
            }
            
            Image(systemName: "tortoise.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
            
            // Custom chunky slider with a fixed thumb
            GeometryReader { geometry in
                let sliderWidth = geometry.size.width
                // Ensure percentage is bound between 0 and 1
                let percentage = CGFloat((scale - 0.5) / 1.5)
                
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 30)
                    
                    // Filled track
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.orange)
                        .frame(width: max(30, percentage * sliderWidth), height: 30)
                    
                    // Thumb (Fixed point)
                    Circle()
                        .fill(Color.white)
                        .shadow(radius: 3)
                        .frame(width: 36, height: 36)
                        .offset(x: percentage * (sliderWidth - 36))
                }
                .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                    // Calculate percentage based on thumb position
                    let newPercentage = min(max(value.location.x / sliderWidth, 0), 1)
                    scale = Float(newPercentage) * 1.5 + 0.5
                    manager.resizeController.setScale(scale, on: manager.animalEntity)
                })
            }
            .frame(height: 30)
            
            Image(systemName: "hare.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 25)
        .onAppear {
            manager.resizeController.enterResizeMode(manager: manager)
            // Re-apply current slider scale to the new spawned model
            manager.resizeController.setScale(scale, on: manager.animalEntity)
        }
        .onDisappear {
            manager.resizeController.exitResizeMode(manager: manager)
        }
    }
}
