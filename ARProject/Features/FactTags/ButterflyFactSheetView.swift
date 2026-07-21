//
//  ButterflyFactSheetViews.swift
//  ARProject
//
//  Created by Ferdiansyah Annora on 21/07/26.
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
            // Native translucent dim background overlay
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header Icon Badge
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: currentIndex < facts.count ? "sparkles" : "person.wave.2.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.orange)
                }
                .padding(.top, 12)
                
                Text(currentIndex < facts.count ? "Butterfly Fun Fact" : "Friend request")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .tracking(1.2)
                
                if currentIndex < facts.count {
                    // Fact Slide View
                    VStack(spacing: 16) {
                        Text(facts[currentIndex].text)
                            .font(.body)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 20)
                            .frame(height: 85)
                        
                        // Page indicator dots
                        HStack(spacing: 6) {
                            ForEach(0...facts.count, id: \.self) { idx in
                                Circle()
                                    .fill(idx == currentIndex ? Color.primary : Color.primary.opacity(0.2))
                                    .frame(width: 7, height: 7)
                            }
                        }
                        
                        // Native iOS Buttons
                        HStack(spacing: 16) {
                            if currentIndex > 0 {
                                Button("Back") {
                                    withAnimation(.spring()) { currentIndex -= 1 }
                                }
                                .buttonStyle(.bordered)
                                .tint(.secondary)
                            }
                            
                            Button(currentIndex == facts.count - 1 ? "Make Friends" : "Next") {
                                withAnimation(.spring()) { currentIndex += 1 }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                        .padding(.top, 8)
                    }
                } else {
                    // Question & Gesture Guide Section (Native HIG Card)
                    VStack(spacing: 16) {
                        Text("Do you want to be friends with the butterfly?")
                            .font(.title3)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "face.smiling.fill")
                                    .font(.title2)
                                    .foregroundStyle(.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Smile")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Accept friendship 😆")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            HStack(spacing: 12) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.red)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Frown / Scrunch Nose")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Decline friendship ☹️")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 4)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 380)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
            .padding(24)
        }
        .onAppear {
            let active = (currentIndex >= facts.count)
            isQuestionActive = active
            if active {
                manager.headGestureController.reset()
            }
        }
        .onChange(of: currentIndex) { idx in
            let active = (idx >= facts.count)
            isQuestionActive = active
            if active {
                manager.headGestureController.reset()
            }
        }
    }
}
