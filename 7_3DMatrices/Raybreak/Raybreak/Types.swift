// Created by Chester for Raybreak in 2025

import simd

struct Vertex {
    var position: SIMD3<Float>
    var color: SIMD4<Float>
    var texture: SIMD2<Float>
}

struct ModelConstants {
    var modelViewMatrix = matrix_identity_float4x4
}
