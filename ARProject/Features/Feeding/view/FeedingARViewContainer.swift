import SwiftUI

struct HandZoneOverlayRepresentable: UIViewRepresentable {
    var state: FeedingOverlayState
    
    func makeUIView(context: Context) -> HandZoneOverlayView {
        let view = HandZoneOverlayView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: HandZoneOverlayView, context: Context) {
        switch state {
        case .reaching:
            uiView.state = .reaching
        case .grabbing:
            uiView.state = .grabbing
        }
    }
}
