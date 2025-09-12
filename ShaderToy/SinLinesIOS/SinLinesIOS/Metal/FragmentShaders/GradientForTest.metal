// Created by Chester for SinLinesIOS in 2025

#include <metal_stdlib>
#include "../MetalTypes.metalh"

using namespace metal;

fragment float4 gradientForTest(
                           const VertexOut vertexIn [[ stage_in ]],
                           constant Uniforms& uniforms [[ buffer(0) ]]
                           ) {
    float2 uv = vertexIn.texCoord; // [0, 1]
    float2 resolution = float2(uniforms.iResolution.x, uniforms.iResolution.y);
    return float4(uv.x, uv.y, resolution.x / resolution.y, 1.0); // 调试颜色
}

