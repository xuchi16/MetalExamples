// Created by Chester for SinLinesIOS in 2025

#include <metal_stdlib>
#include "../MetalTypes.metalh"
using namespace metal;

vertex VertexOut vertexShader(
                              VertexIn in [[stage_in]],
                              uint vertexID [[vertex_id]]
                              ) {
    VertexOut out;
    out.position = float4(in.position, 0.0, 1.0);
    out.texCoord = in.texCoord;
    return out;
}
