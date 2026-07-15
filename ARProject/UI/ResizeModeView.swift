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
            
            // Custom chunky slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 30)
                    
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.orange)
                        .frame(width: max(30, CGFloat((scale - 0.5) / 1.5) * geometry.size.width), height: 30)
                        .shadow(color: .orange.opacity(0.5), radius: 5, x: 0, y: 0)
                }
                .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                    let percentage = min(max(value.location.x / geometry.size.width, 0), 1)
                    scale = Float(percentage) * 1.5 + 0.5
                    manager.setScale(scale)
                })
            }
            .frame(height: 30)
            
            Image(systemName: "hare.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 25)
    }
}
