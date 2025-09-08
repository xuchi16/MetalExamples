// Created by Chester for MetalCubeExample in 2025

#include <metal_stdlib>
#include "CubeShaderTypes.h"
using namespace metal;

constant uint planeOrder[6] = {0, 5, 3, 1, 4, 2};

kernel void updateCubeMesh(device CubeVertex* vertices [[buffer(0)]],
                         device uint* indices [[buffer(1)]],
                         constant CubeParams& params [[buffer(2)]],
                         uint id [[thread_position_in_grid]])
{
    // Calculate which face and vertex we're working with
    uint verticesPerPlane = params.dimensions_x * params.dimensions_y;
    uint planeIndex = id / verticesPerPlane;
    uint vertexInPlane = id % verticesPerPlane;
    
    if (planeIndex >= 6) return;
    
    uint x = vertexInPlane % params.dimensions_x;
    uint y = vertexInPlane / params.dimensions_x;
    
    float u = float(x) / float(params.dimensions_x - 1);
    float v = float(y) / float(params.dimensions_y - 1);
    
    float3 position;
    float3 normal;
    
    // Match the exact same face ordering as the original:
    // Front (Z+), Back (Z-), Right (X+), Left (X-), Top (Y+), Bottom (Y-)
    switch(planeIndex) {
        case 0: // Front face (Z+)
            position = float3(
                params.size.x * (u - 0.5),
                params.size.y * (v - 0.5),
                params.size.z * 0.5
            );
            normal = float3(0, 0, 1);
            break;
            
        case 1: // Back face (Z-)
            position = float3(
                params.size.x * (u - 0.5),
                params.size.y * (v - 0.5),
                params.size.z * -0.5
            );
            normal = float3(0, 0, -1);
            break;
            
        case 2: // Right face (X+)
            position = float3(
                params.size.x * 0.5,
                params.size.y * (v - 0.5),
                params.size.z * (0.5 - u)
            );
            normal = float3(1, 0, 0);
            break;
            
        case 3: // Left face (X-)
            position = float3(
                params.size.x * -0.5,
                params.size.y * (v - 0.5),
                params.size.z * (0.5 - u)
            );
            normal = float3(-1, 0, 0);
            break;
            
        case 4: // Top face (Y+)
            position = float3(
                params.size.x * (u - 0.5),
                params.size.y * 0.5,
                params.size.z * (0.5 - v)
            );
            normal = float3(0, 1, 0);
            break;
            
        case 5: // Bottom face (Y-)
            position = float3(
                params.size.x * (u - 0.5),
                params.size.y * -0.5,
                params.size.z * (0.5 - v)
            );
            normal = float3(0, -1, 0);
            break;
    }
    
    // Proportionally normalize based on normalization factor (0 = cube, 1 = fully normalized)
    float3 scale = params.size * 0.5;
    float3 normalizedPos = normalize(position) * scale;
    position = mix(position, normalizedPos, params.cubeSphereInterpolationRatio);
    
    vertices[id].position = position;
    vertices[id].normal = normalize(position);
    
    // Update indices in this order [0,5,3,1,4,2]
    if (x < params.dimensions_x - 1 && y < params.dimensions_y - 1) {
        // Convert planeIndex to the desired order
        
        uint orderedPlaneIndex = 0;
        for (uint i = 0; i < 6; i++) {
            if (planeIndex == planeOrder[i]) {
                orderedPlaneIndex = i;
                break;
            }
        }
        
        uint indexBase = (orderedPlaneIndex * (params.dimensions_x - 1) * (params.dimensions_y - 1) +
                         y * (params.dimensions_x - 1) + x) * 6;
        
        uint bottomLeft = vertexInPlane;
        uint bottomRight = bottomLeft + 1;
        uint topLeft = bottomLeft + params.dimensions_x;
        uint topRight = topLeft + 1;
        
        // Add plane offset to indices
        bottomLeft += planeIndex * verticesPerPlane;
        bottomRight += planeIndex * verticesPerPlane;
        topLeft += planeIndex * verticesPerPlane;
        topRight += planeIndex * verticesPerPlane;
        
        // Match the winding order from the original implementation
        if (planeIndex == 1 || planeIndex == 3 || planeIndex == 5) {
            // Back, Left, Bottom faces need reversed winding
            indices[indexBase] = bottomLeft;
            indices[indexBase + 1] = topLeft;
            indices[indexBase + 2] = bottomRight;
            indices[indexBase + 3] = bottomRight;
            indices[indexBase + 4] = topLeft;
            indices[indexBase + 5] = topRight;
        } else {
            // Front, Right, Top faces keep original winding
            indices[indexBase] = bottomLeft;
            indices[indexBase + 1] = bottomRight;
            indices[indexBase + 2] = topLeft;
            indices[indexBase + 3] = topLeft;
            indices[indexBase + 4] = bottomRight;
            indices[indexBase + 5] = topRight;
        }
    }
}
