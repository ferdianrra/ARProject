import SwiftUI

struct FeedingGuideModalView: View {
    @Binding var isPresented: Bool
    var animalName: String
    
    var body: some View {
        ZStack {
            // Darkened background
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.gray)
                    }
                }
                
                Text("Time to eat!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Grab the correct food for the \(animalName.capitalized)!")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 20) {
                    GuideRow(icon: "hand.point.up.fill", color: .blue, text: "Point your hand at the food. A sphere will appear!")
                    GuideRow(icon: "circle.fill", color: .red, text: "Red sphere means you are too far away.")
                    GuideRow(icon: "circle.fill", color: .yellow, text: "Yellow sphere means you are close to the food!")
                    GuideRow(icon: "circle.fill", color: .green, text: "Green sphere means you are hovering over the food!")
                    GuideRow(icon: "hand.draw.fill", color: .orange, text: "When it turns green, pinch your thumb and index finger together to grab it!")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("OK! Let's Feed!")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 32)
                        .background(Color.green)
                        .cornerRadius(20)
                        .shadow(color: Color.green.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.top, 10)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .shadow(radius: 20)
            .padding(32)
        }
    }
}

struct GuideRow: View {
    var icon: String
    var color: Color
    var text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(text)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
