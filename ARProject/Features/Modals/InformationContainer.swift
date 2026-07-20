import SwiftUI

struct InformationContainer: View {
    let message: String
    let isWarning: Bool // true = Yellow theme, false = Green theme
    let onDismiss: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 16) {
                // Main Content Text
                Text(message)
                    .font(.system(size: 16, weight: .bold, design: .rounded)) // Upped weight to bold for better readability
                    .foregroundColor(
                        isWarning
                        ? Color(red: 0.25, green: 0.20, blue: 0.05) // Deep Charcoal Brown
                        : Color(red: 0.05, green: 0.22, blue: 0.12) // Deep Forest Green
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                
                // Bottom-right aligned small action button
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Text(isWarning ? "Try Again" : "Got it")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(isWarning ? Color(red: 0.65, green: 0.45, blue: 0.05) : Color(red: 0.1, green: 0.45, blue: 0.2))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.6))
                            )
                    }
                }
            }
            .padding(20)
            // Background is a clean, solid pastel panel
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isWarning ? Color(red: 0.99, green: 0.96, blue: 0.82) : Color(red: 0.88, green: 0.96, blue: 0.91))
            )
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
            // Constraints container width to exactly 1/3 of the current screen width
            .frame(width: geometry.size.width / 3)
            // Centers the container layout inside the geometry frame
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}


// MARK: - Previews
#Preview("Information Container (Pastel Green)") {
    ZStack {
        Color.gray.opacity(0.15).ignoresSafeArea()
        InformationContainer(
            message: "Open your mouth and smile at the camera to connect with the animal.",
            isWarning: false,
            onDismiss: {}
        )
    }
}

#Preview("Warning Container (Pastel Yellow)") {
    ZStack {
        Color.gray.opacity(0.15).ignoresSafeArea()
        InformationContainer(
            message: "Face your palm up and curl your fingers inward to call the animal over.",
            isWarning: true,
            onDismiss: {}
        )
    }
}
