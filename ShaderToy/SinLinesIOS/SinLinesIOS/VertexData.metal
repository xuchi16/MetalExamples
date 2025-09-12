// Created by Chester for SinLinesIOS in 2025

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexShader(
    VertexIn in [[stage_in]],
    uint vertexID [[vertex_id]]
) {
    VertexOut out;
    out.position = float4(in.position, 0.0, 1.0);
    out.texCoord = in.texCoord;
    return out;
}

// Fragment shader
struct Uniforms {
    float4 iResolution;
    float iTime;
};

fragment float4 mainImage(
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
        uv.y += sin(uv.x * i + t + i / 2.0) * 0.2;
        float fTemp = abs(1.0 / uv.y / 100.0);
        color += float3(fTemp * (10.0 - i) / 10.0,
                       fTemp / 10.0,
                       fTemp * 1.5);
    }
    
    return float4(color, 1.0);
}
