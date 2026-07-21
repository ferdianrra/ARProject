//
//  ButterflyFactSheetView.swift
//  ARProject
//

import SwiftUI

struct ButterflyFactSheetView: View {
    @State private var currentIndex: Int = 0
    @Binding var isPresented: Bool
    @Binding var isQuestionActive: Bool
    var onDecision: (HeadDecision) -> Void
    
    @EnvironmentObject var manager: ARManager
    
    private let facts = ButterflyFactData.facts
    
    var body: some View {
        ZStack {
            // Darkened backdrop with smooth blur
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissModal()
                }
            
            VStack(spacing: 20) {
                // Top Bar: Category Pill & Close Button
                HStack {
                    HStack(spacing: 6) {
                        Text(currentIndex < facts.count ? "✨ FUN FACT \(currentIndex + 1)/\(facts.count)" : "🤝 FRIENDSHIP")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.15), in: Capsule())
                    
                    Spacer()
                    
                    Button(action: {
                        dismissModal()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
                
                if currentIndex < facts.count {
                    let fact = facts[currentIndex]
                    
                    // Fact Content
                    VStack(spacing: 16) {
                        // Emoji Badge
                        Text(fact.emoji)
                            .font(.system(size: 44))
                            .padding(16)
                            .background(Color.orange.opacity(0.12), in: Circle())
                        
                        Text(fact.title)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(fact.text)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                            .padding(.horizontal, 8)
                            .frame(height: 70)
                        
                        // Page Dots Indicator
                        HStack(spacing: 6) {
                            let totalDots = manager.isFirstDiscoveryFact ? facts.count + 1 : facts.count
                            ForEach(0..<totalDots, id: \.self) { idx in
                                Capsule()
                                    .fill(idx == currentIndex ? Color.orange : Color.primary.opacity(0.2))
                                    .frame(width: idx == currentIndex ? 18 : 6, height: 6)
                                    .animation(.spring(), value: currentIndex)
                            }
                        }
                        .padding(.top, 4)
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            if currentIndex > 0 {
                                Button(action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        currentIndex -= 1
                                    }
                                }) {
                                    Text("Back")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                                }
                            }
                            
                            Button(action: {
                                if currentIndex < facts.count - 1 {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        currentIndex += 1
                                    }
                                } else if manager.isFirstDiscoveryFact && currentIndex == facts.count - 1 {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        currentIndex += 1
                                    }
                                } else {
                                    dismissModal()
                                }
                            }) {
                                Text(currentIndex == facts.count - 1 ? (manager.isFirstDiscoveryFact ? "Make Friends" : "Got it") : "Next")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(.top, 8)
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                } else {
                    // Friend Request View
                    VStack(spacing: 18) {
                        Text("🦋")
                            .font(.system(size: 44))
                            .padding(16)
                            .background(Color.orange.opacity(0.12), in: Circle())
                        
                        VStack(spacing: 6) {
                            Text("Wanna be friends?")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Use your facial expressions to answer:")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 12) {
                            // Smile Option Card
                            Button(action: {
                                onDecision(.accepted)
                            }) {
                                HStack(spacing: 14) {
                                    Text("😆")
                                        .font(.system(size: 28))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Smile")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundColor(.green)
                                        Text("Accept friendship")
                                            .font(.system(size: 13, weight: .regular, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.green)
                                }
                                .padding(14)
                                .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.3), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            
                            // Frown Option Card
                            Button(action: {
                                onDecision(.rejected)
                            }) {
                                HStack(spacing: 14) {
                                    Text("☹️")
                                        .font(.system(size: 28))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Frown or Scrunch Nose")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundColor(.red)
                                        Text("Decline friendship")
                                            .font(.system(size: 13, weight: .regular, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.red)
                                }
                                .padding(14)
                                .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.3), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
            .padding(24)
            .frame(maxWidth: 380)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 30, x: 0, y: 15)
            .padding(24)
        }
        .onAppear {
            updateQuestionState()
        }
        .onChange(of: currentIndex) { _ in
            updateQuestionState()
        }
    }
    
    private func updateQuestionState() {
        let active = (currentIndex >= facts.count)
        isQuestionActive = active
        if active {
            manager.headGestureController.reset()
        }
    }
    
    private func dismissModal() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isPresented = false
            isQuestionActive = false
        }
    }
}
