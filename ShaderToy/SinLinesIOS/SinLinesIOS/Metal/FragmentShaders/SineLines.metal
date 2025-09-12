// Created by Chester for SinLinesIOS in 2025

#include <metal_stdlib>
#include "../MetalTypes.metalh"
using namespace metal;

// https://www.shadertoy.com/new
fragment float4 sineLines(
                          const VertexOut vertexIn [[ stage_in ]],
                          constant Uniforms& uniforms [[ buffer(0) ]]
                          ) {
    float2 fragCoord = vertexIn.position.xy;
    float2 iResolution = float2(uniforms.iResolution.x, uniforms.iResolution.y);
    float iTime = uniforms.iTime;
    
    float2 uv = (2.0 * fragCoord - iResolution) / iResolution.y;
    uv.x -= 1.0;
    
    float3 color = float3(0.0);
    
    for (float i = 1.0; i < 15.0; ++i) {
        float t = iTime;
        uv.y += sin(uv.x * i + t + i / 2.0) * 0.1;
        float fTemp = abs(0.01 / uv.y);
        color += float3(fTemp * (10.0 - i) / 10.0,  // r
                        fTemp / 10.0,                // g
                        fTemp * 1.5);                // b
    }
    
    return float4(color, 1.0);
}
