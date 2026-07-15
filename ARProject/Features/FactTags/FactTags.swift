import SwiftUI

struct NameTagView: View {
    var body: some View {
        VStack {
            Text("The African Giant Swallowtail")
                .font(.headline)
            Text("(Papilio antimachus)")
                .font(.subheadline).italic()
        }
        .padding(10)
        .background(Color.purple.opacity(0.85))
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct LocationTagView: View {
    var body: some View {
        VStack {
            Text("Location")
                .font(.caption).bold()
            Text("West & Central Africa")
                .font(.caption)
        }
        .padding(10)
        .background(Color.blue.opacity(0.85))
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatusTagView: View {
    var body: some View {
        VStack {
            Text("Endangered Status")
                .font(.caption).bold()
            Text("Data Deficient (DD)")
                .font(.caption)
        }
        .padding(10)
        .background(Color.orange.opacity(0.85))
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SizeTagView: View {
    var body: some View {
        VStack {
            Text("Size")
                .font(.caption).bold()
            Text("Wingspan 18-23 cm")
                .font(.caption)
        }
        .padding(10)
        .background(Color.green.opacity(0.85))
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
