import SwiftUI

struct FeedModeView: View {
    @Binding var currentState: PanelState
    
    @State private var showFeedFeedback: Bool = false
    @State private var feedFeedbackMessage: String = ""
    @State private var isCorrectFood: Bool = false
    
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
        .overlay(
            Group {
                if showFeedFeedback {
                    Text(feedFeedbackMessage)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                        .background(isCorrectFood ? Color.green.opacity(0.9) : Color.red.opacity(0.9))
                        .cornerRadius(15)
                        .shadow(radius: 10)
                        .offset(y: -120) // Pushes it right above the panel
                        .transition(.scale.combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    showFeedFeedback = false
                                }
                            }
                        }
                }
            }
        )
    }
    
    private func triggerFeedFeedback(correct: Bool) {
        isCorrectFood = correct
        if correct {
            feedFeedbackMessage = "Yum! Great Choice! I’m a Herbivore, so I eat plants."
        } else {
            feedFeedbackMessage = "Oops! That’s not the right food. Try another meal!"
        }
        withAnimation(.spring()) {
            showFeedFeedback = true
        }
    }
}
