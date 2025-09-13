// Created by Chester for SinLinesIOS in 2025
// https://www.shadertoy.com/view/7tBSR1

#include <metal_stdlib>
#include "../MetalTypes.metalh"

using namespace metal;

// 随机数生成函数
float rand(float2 p) {
    p *= 500.0;
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// 值噪声
float noise(float2 p) {
    float2 f = smoothstep(0.0, 1.0, fract(p));
    float2 i = floor(p);
    float a = rand(i);
    float b = rand(i + float2(1.0, 0.0));
    float c = rand(i + float2(0.0, 1.0));
    float d = rand(i + float2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// 分形布朗运动（分形噪声）
float fbm(float2 p) {
    float a = 0.5;
    float r = 0.0;
    for (int i = 0; i < 8; i++) {
        r += a * noise(p);
        a *= 0.5;
        p *= 2.0;
    }
    return r;
}

// 从中心点发出的激光
float laser(float2 p, int num, float iTime) {
    float r = atan2(p.x, p.y);
    float sn = sin(r * float(num) + iTime);
    float lzr = 0.5 + 0.5 * sn;
    lzr = lzr * lzr * lzr * lzr * lzr;
    float glow = pow(clamp(sn, 0.0, 1.0), 100.0);
    return lzr + glow;
}

// 混合分形噪声模拟雾效
float clouds(float2 uv, float iTime) {
    float2 t = float2(0.0, iTime);
    float c1 = fbm(fbm(uv * 3.0) * 0.75 + uv * 3.0 + t / 3.0);
    float c2 = fbm(fbm(uv * 2.0) * 0.5 + uv * 7.0 + t / 3.0);
    float c3 = fbm(fbm(uv * 10.0 - t) * 0.75 + uv * 5.0 + t / 6.0);
    float r = mix(c1, c2, c3 * c3);
    return r * r;
}

fragment float4 raveLasers(
    const VertexOut vertexIn [[stage_in]],
    constant Uniforms& uniforms [[buffer(0)]]
) {
    float2 fragCoord = vertexIn.position.xy;
    float2 iResolution = float2(uniforms.iResolution.x, uniforms.iResolution.y);
    float iTime = uniforms.iTime;
    
    float2 uv = fragCoord / iResolution.y;
    float2 hs = iResolution.xy / iResolution.y * 0.5;
    float2 uvc = uv - hs;
    
//    float l = (1.0 + 3.0 * noise(float2(15.0 - iTime)))
//             * laser(float2(uv.x + 0.5, uv.y * (0.5 + 10.0 * noise(float2(iTime / 5.0))) + 0.1), 15, iTime);
//    
//    l += fbm(float2(2.0 * iTime))
//        * laser(float2(hs.x - uvc.x - 0.2, uv.y + 0.1), 25, iTime);
//    
//    l += noise(float2(iTime - 73.0))
//        * laser(float2(uvc.x, 1.0 - uv.y + 0.5), 30, iTime);
    
    
    float l =laser(float2(uv.x + 0.5, uv.y * (0.5 + 10.0 * noise(float2(iTime / 5.0))) + 0.1), 15, iTime);
    
    l += laser(float2(hs.x - uvc.x - 0.2, uv.y + 0.1), 25, iTime);
    
    l += laser(float2(uvc.x, 1.0 - uv.y + 0.5), 30, iTime);
    
    float c = clouds(uv, iTime);
    float4 col = float4(0.0, 1.0, 0.0, 1.0) * (uv.y * l + uv.y * uv.y) * c;
    
    return pow(col, float4(0.75));
}
