// Created by Chester for SinLinesIOS in 2025

#include <metal_stdlib>
#include "MetalTypes.metalh"
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

fragment float4 mainImage2(
                           const VertexOut vertexIn [[ stage_in ]],
                           constant Uniforms& uniforms [[ buffer(0) ]]
                           ) {
    float2 uv = vertexIn.texCoord; // [0, 1]
    float2 resolution = float2(uniforms.iResolution.x, uniforms.iResolution.y);
    return float4(uv.x, uv.y, resolution.x / resolution.y, 1.0); // 调试颜色
}

// https://www.shadertoy.com/view/wd3SDH
fragment float4 mainImage3(const VertexOut vertexIn [[ stage_in ]],
                           constant Uniforms& uniforms [[ buffer(0) ]]
                           ) {
    float2 fragCoord = vertexIn.position.xy;
    
    float r, g, b;
    
    r = 0.2;
    g = 0.2;
    b = 0.57;
    
    float time = uniforms.iTime * 4.0;
    float ot1 = 5.0;
    float ot3 = 2.0;
    float ot5 = 0.1;
    float ot7 = 0.01;
    
    float2 uv = fragCoord.xy / uniforms.iResolution.xy;
    float amnt;
    float nd;
    float ip;
    float alpha;
    float4 cbuff = float4(0.0);
    
    for (float i = 0.0; i < 10.0; i++) {
        ip = i - 2.0;
        
        // 使用M_PI_F作为π的近似值
        nd = 1.0 / 4.0 * ot1 * sin(uv.x * 2.0 * M_PI_F + ip * 0.4 + time * 0.05) / 2.0;
        nd += 1.0 / 4.0 * ot3 * sin(3.0 * uv.x * 2.0 * M_PI_F + ip * 0.4) / 2.0;
        nd += 1.0 / 4.0 * ot5 * sin(5.0 * uv.x * 2.0 * M_PI_F + ip * 0.4) / 2.0;
        nd += 1.0 / 4.0 * ot7 * sin(7.0 * uv.x * 2.0 * M_PI_F + ip * 0.4) / 2.0;
        
        nd /= 5.0;
        nd += 0.5;
        amnt = 1.0 / abs(nd - uv.y) * 0.01;
        
        // Metal中的smoothstep函数
        amnt = smoothstep(0.01, 0.5 + 10.0 * uv.y, amnt) * 5.5;
        
        alpha = (10.0 - i) / 5.0;
        cbuff += float4(amnt * alpha * 0.3, amnt * 0.3 * alpha, amnt * uv.y * alpha, 0.0);
    }
    
    return float4(cbuff[0] * r, cbuff[1] * g, cbuff[2] * b, 1.0);
}
