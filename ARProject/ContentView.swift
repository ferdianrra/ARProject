import SwiftUI
import RealityKit
import ARKit

struct ContentView : View {
    @StateObject private var arManager = ARManager()
    @State private var auraTimer: Timer?
    @State private var auraPhase: Float = 0
    @State private var ringEntity: ModelEntity?
    @State private var sceneUpdateSubscription: EventSubscription?

    var body: some View {
        ZStack {
            RealityView { content in
                let camAnchor = AnchorEntity(.camera)
                let ringMesh = MeshResource.generateRing(innerRadius: 0.95, outerRadius: 1.0)
                var blueMaterial = PhysicallyBasedMaterial()
               
                blueMaterial.baseColor = .init(tint: .black)
                blueMaterial.emissiveColor = .init(color: .init(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0))
                blueMaterial.emissiveIntensity = 3.0
                blueMaterial.roughness = .init(floatLiteral: 0.1)
                blueMaterial.metallic = .init(floatLiteral: 0.0)
                blueMaterial.faceCulling = .none
                blueMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.85))
                
                content.add(camAnchor)
                arManager.cameraAnchor = camAnchor
                
                let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
                content.add(anchor)

                content.camera = .spatialTracking
                
                let ring = ModelEntity(mesh: ringMesh, materials: [blueMaterial])
                anchor.addChild(ring)
                
                let circleMesh = MeshResource.generateCircle(radius: 1.0)
                let circle = ModelEntity(mesh: circleMesh, materials: [blueMaterial])
                circle.position = [0, 0.02, 0]
                anchor.addChild(circle)
                self.ringEntity = circle
                
                auraTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                    guard let circle = self.ringEntity else { return }
                    self.auraPhase += 0.05
                    let pulse = (sin(self.auraPhase) + 1) / 2
                    var mat = PhysicallyBasedMaterial()
                    mat.baseColor = .init(tint: .black)
                    mat.emissiveColor = .init(color: .init(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0))
                    mat.emissiveIntensity = 2.0 + pulse * 3.0
                    mat.roughness = .init(floatLiteral: 0.1)
                    mat.metallic = .init(floatLiteral: 0.0)
                    mat.faceCulling = .none
                    mat.blending = .transparent(opacity: .init(floatLiteral: 0.85))
                    circle.model?.materials = [mat]
                }
                
                arManager.setup(cameraAnchor: camAnchor, planeAnchor: anchor)
                
                self.sceneUpdateSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                    arManager.updateScene()
                }
            } update: { content in
            }
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text(arManager.distanceText)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding(.top, 50)
                
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}

