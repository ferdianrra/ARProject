import SwiftUI

struct FeedModeView: View {
    @Binding var currentState: PanelState
    @ObservedObject var manager: ARManager

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Button(action: { currentState = .mainButtons }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.red.opacity(0.9))
                }
                Spacer()
                Text("What to feed?")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }

            HStack(spacing: 30) {
                Button(action: { triggerFeedFeedback(correct: true) }) {
                    Text("🍃")
                        .font(.system(size: 40))
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }

                Button(action: { triggerFeedFeedback(correct: false) }) {
                    Text("🥩")
                        .font(.system(size: 40))
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }

    private func triggerFeedFeedback(correct: Bool) {
        if correct {
            manager.triggerFeedback(
                message: "Yum! Great Choice! I’m a Herbivore, so I eat plants.",
                tone: .positive,
                haptic: .success,
                sound: .positiveChime
            )
        } else {
            manager.triggerFeedback(
                message: "Oops! That’s not the right food. Try another meal!",
                tone: .negative,
                haptic: .warning,
                sound: .negativeBuzz
            )
        }
    }
}
