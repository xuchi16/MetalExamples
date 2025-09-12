// Created by Chester for SinLinesIOS in 2025

import Foundation


struct VertexIn {
    var position: SIMD2<Float>
    var texCoord: SIMD2<Float>
}

struct ShaderUniforms {
    var iResolution: SIMD4<Float>
    var iTime: Float
}
