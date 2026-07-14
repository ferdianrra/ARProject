//
//  ContentView.swift
//  ARProject
//
//  Created by Ferdiansyah Annora on 13/07/26.
//

import SwiftUI
import RealityKit

struct ContentView : View {
    @StateObject private var manager = ARManager()
    @State private var scanPulse = false
    let animalModels = ["cat", "calf", "merak", "zebra"]
    
    var body: some View {
        RealityView { content in
            let camAnchor = AnchorEntity(.camera)
            content.add(camAnchor)
            manager.cameraAnchor = camAnchor
            
            // Create a cube model
            let model = Entity()
            let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
            let material = SimpleMaterial(color: .gray, roughness: 0.15, isMetallic: true)
            model.components.set(ModelComponent(mesh: mesh, materials: [material]))
            model.position = [0, 0.05, 0]

            // Create horizontal plane anchor for the content
            let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
            anchor.addChild(model)

            // Add the horizontal plane anchor to the scene
            content.add(anchor)

            content.camera = .spatialTracking

        }
        .edgesIgnoringSafeArea(.all)
    }

}

#Preview {
    ContentView()
}
