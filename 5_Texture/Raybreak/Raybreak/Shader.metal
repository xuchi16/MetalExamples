// Created by Chester for Raybreak in 2025

#include <metal_stdlib>
using namespace metal;

struct Constants {
    float animatedBy;
};

struct VertexIn {
    float4 position [[ attribute(0) ]]; // 即使Swift定义里这里是 float3，也得用float4来获取该参数
    float4 color [[ attribute(1) ]];
};

struct VertexOut {
    float4 position [[ position ]];
    float4 color;
};

vertex VertexOut vertex_shader(const VertexIn vertexIn [[ stage_in ]]) {
    
    VertexOut vertexOut;
    vertexOut.position = vertexIn.position;
    vertexOut.color = vertexIn.color;
    
    return vertexOut;
}

// 这里入参的 color 是已经经过栅格化流程，内插处理过后的结果
fragment half4 fragment_shader(VertexOut vertexIn [[ stage_in ]]) {
    return half4(vertexIn.color);
}
