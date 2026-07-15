import SwiftUI
import RealityKit
import ARKit

struct ContentView : View {
    @StateObject private var arManager = ARManager()
    @State private var sceneUpdateSubscription: EventSubscription?

    var body: some View {
        ZStack {
            RealityView { content in
                let camAnchor = AnchorEntity(.camera)
                content.add(camAnchor)
                arManager.cameraAnchor = camAnchor
                
                let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
                content.add(anchor)

                content.camera = .spatialTracking
                
                arManager.setup(cameraAnchor: camAnchor, planeAnchor: anchor)
                
                self.sceneUpdateSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                    arManager.updateScene()
                }
            } update: { content in
            }
            .edgesIgnoringSafeArea(.all)
            
//            VStack {
//                Text(arManager.distanceText)
//                    .font(.title2)
//                    .bold()
//                    .foregroundColor(.white)
//                    .padding()
//                    .background(Color.black.opacity(0.7))
//                    .cornerRadius(10)
//                    .padding(.top, 50)
//                
//                Spacer()
//            }
        }
    }
}

#Preview {
    ContentView()
}

