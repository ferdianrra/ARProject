import SwiftUI

struct FeedingModeView: View {
    @Binding var currentState: PanelState
    @ObservedObject var manager: ARManager
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: { currentState = .mainButtons }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.red.opacity(0.9))
            }
            
            HStack {
                Text(messageText)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                // Circular sphere clue that changes color
                Circle()
                    .fill(statusColor)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.8), lineWidth: 2)
                    )
                    .shadow(color: statusColor.opacity(0.6), radius: 4, x: 0, y: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.2))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .onAppear {
            manager.startFeedingMode()
            manager.isFeedingActive = true
        }
        .onDisappear {
            manager.stopFeedingMode()
            manager.isFeedingActive = false
        }
    }
    
    private var messageText: String {
        switch manager.feedingOverlayState {
        case .reaching:
            return "Pinch and drag the food!"
        case .feeding:
            return "Butterfly is eating!"
        }
    }
    
    private var statusColor: Color {
        switch manager.feedingOverlayState {
        case .reaching:
            return .orange
        case .feeding:
            return .green
        }
    }
}
