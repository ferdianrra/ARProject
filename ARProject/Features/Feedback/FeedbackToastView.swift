import SwiftUI

/// Renders `manager.feedbackEvent` when it carries a message. Events with
/// `message == nil` (facts toggle, spot discovery) are haptic/sound-only —
/// the caller in ContentView skips mounting this view for those.
struct FeedbackToastView: View {
    let event: FeedbackEvent
    let onDismiss: () -> Void

    var body: some View {
        Text(event.message ?? "")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding()
            .background(event.tone == .positive ? Color.green.opacity(0.9) : Color.red.opacity(0.9))
            .clipShape(.rect(cornerRadius: 15))
            .shadow(radius: 10)
            .transition(.scale.combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    onDismiss()
                }
            }
    }
}
