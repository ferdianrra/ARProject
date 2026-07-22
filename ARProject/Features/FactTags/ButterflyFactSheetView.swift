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
    
    private var facts: [ButterflyFact] {
        let typeName = manager.currentFactSpot?.animalTypeName ?? "butterfly"
        return AnimalFactData.facts(for: typeName)
    }
    
    var body: some View {
        ZStack {
            // Darkened backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissModal()
                }
            
            VStack(spacing: 18) {
                // Top Bar: Simple Title & Close Button
                HStack {
                    Text(currentIndex < facts.count ? "Did You Know?" : "Wanna Be Friends?")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        dismissModal()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Color.primary.opacity(0.06), in: Circle())
                    }
                }
                
                if currentIndex < facts.count {
                    let fact = facts[currentIndex]
                    
                    // Simple Fact Content
                    VStack(alignment: .leading, spacing: 12) {
                        Text(fact.text)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                            .frame(minHeight: 70, alignment: .topLeading)
                        
                        // Page Dots Indicator
                        HStack(spacing: 6) {
                            Spacer()
                            let totalDots = manager.isFirstDiscoveryFact ? facts.count + 1 : facts.count
                            ForEach(0..<totalDots, id: \.self) { idx in
                                Circle()
                                    .fill(idx == currentIndex ? Color.primary : Color.primary.opacity(0.2))
                                    .frame(width: 6, height: 6)
                            }
                            Spacer()
                        }
                        .padding(.top, 4)
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            if currentIndex > 0 {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        currentIndex -= 1
                                    }
                                }) {
                                    Text("Back")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            
                            Button(action: {
                                if currentIndex < facts.count - 1 {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        currentIndex += 1
                                    }
                                } else if manager.isFirstDiscoveryFact && currentIndex == facts.count - 1 {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        currentIndex += 1
                                    }
                                } else {
                                    dismissModal()
                                }
                            }) {
                                Text(currentIndex == facts.count - 1 ? (manager.isFirstDiscoveryFact ? "Make Friends" : "Got it") : "Next")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.top, 4)
                    }
                } else {
                    // Friend Request Options
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Choose how to respond:")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 10) {
                            // Smile Option
                            Button(action: {
                                onDecision(.accepted)
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "face.smiling.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.yellow)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Smile")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                        Text("Accept friendship")
                                            .font(.system(size: 13, weight: .regular, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            
                            // Frown Option
                            Button(action: {
                                onDecision(.rejected)
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "face.dashed")
                                        .font(.system(size: 24))
                                        .foregroundColor(.red)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Frown / Scrunch Nose")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                        Text("Decline friendship")
                                            .font(.system(size: 13, weight: .regular, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 340)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            .padding(20)
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
