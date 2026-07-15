import RealityKit
import Foundation

extension MeshResource {
    static func generateRing(innerRadius: Float, outerRadius: Float, segments: Int = 64) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []

        for i in 0...segments {
            let angle = (Float(i) / Float(segments)) * 2 * Float.pi
            let cosA = cos(angle)
            let sinA = sin(angle)

            positions.append(SIMD3<Float>(cosA * outerRadius, 0, sinA * outerRadius))
            normals.append(SIMD3<Float>(0, 1, 0))
            uvs.append(SIMD2<Float>(Float(i) / Float(segments), 1))

            positions.append(SIMD3<Float>(cosA * innerRadius, 0, sinA * innerRadius))
            normals.append(SIMD3<Float>(0, 1, 0))
            uvs.append(SIMD2<Float>(Float(i) / Float(segments), 0))
        }

        for i in 0..<segments {
            let outerCurrent = UInt32(i * 2)
            let innerCurrent = UInt32(i * 2 + 1)
            let outerNext = UInt32((i + 1) * 2)
            let innerNext = UInt32((i + 1) * 2 + 1)

            indices.append(contentsOf: [outerCurrent, innerCurrent, outerNext])
            indices.append(contentsOf: [innerCurrent, innerNext, outerNext])
        }

        var descriptor = MeshDescriptor(name: "ring")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        descriptor.primitives = .triangles(indices)

        return try! MeshResource.generate(from: [descriptor])
    }
    
    static func generateCircle(radius: Float, segments: Int = 64) -> MeshResource {
        var positions: [SIMD3<Float>] = [SIMD3<Float>(0, 0, 0)]
        var normals: [SIMD3<Float>] = [SIMD3<Float>(0, 1, 0)]
        var uvs: [SIMD2<Float>] = [SIMD2<Float>(0.5, 0.5)]
        var indices: [UInt32] = []

        for i in 0...segments {
            let angle = (Float(i) / Float(segments)) * 2 * Float.pi
            let x = cos(angle) * radius
            let z = sin(angle) * radius

            positions.append(SIMD3<Float>(x, 0, z))
            normals.append(SIMD3<Float>(0, 1, 0))
            uvs.append(SIMD2<Float>(cos(angle) * 0.5 + 0.5, sin(angle) * 0.5 + 0.5))

            if i < segments {
                indices.append(0)
                indices.append(UInt32(i + 1))
                indices.append(UInt32(i + 2))
            }
        }

        var descriptor = MeshDescriptor(name: "circle")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        descriptor.primitives = .triangles(indices)

        return try! MeshResource.generate(from: [descriptor])
    }
}
