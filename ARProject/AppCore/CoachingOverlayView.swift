//
//  CoachingOverlayView.swift
//  ARProject
//

import SwiftUI

struct CoachingOverlayView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
//            Text("Find a flat surface!")
            Text("Look down at the floor!")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
            
            Image(systemName: "ipad.landscape")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                .rotationEffect(Angle(degrees: isAnimating ? 15 : -15))
                .animation(
                    Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            Text("Move your iPad slowly side to side.")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(AnyShapeStyle(.ultraThinMaterial))
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        )
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ZStack {
        Color.blue.edgesIgnoringSafeArea(.all)
        CoachingOverlayView()
    }
}
