// Created by Chester for MarchingCube in 2025

#include <metal_stdlib>
using namespace metal;

#include "VertexData.h"
#include "MarchingCubesParams.h"
#include "edgeTable.h"
#include "triTable.h"

inline float sdf_sphere(float3 p, float3 c, float r) {
    return length(p - c) - r;
}

inline float3 interpolateIsoSurfacePosition(float3 pA, float valueA,
                                            float3 pB, float valueB,
                                            float isoLevel) {
    float denom = (valueB - valueA);
    float t = (isoLevel - valueA) / (denom + 1e-6f);
    return mix(pA, pB, clamp(t, 0.0f, 1.0f));
    // 取中点如下即可
    // return (pA + pB) * 0.5f;
}

inline float3 estimateNormalFromField(float3 worldPos, constant MarchingCubesParams& P) {
    float h = 0.5f * min(P.cellSize.x, min(P.cellSize.y, P.cellSize.z));
    return normalize(worldPos / (2.0f * h));    // TODO: 这里的法线计算没搞明白
}

kernel void marchingCubesShape(device VertexData* outVertices [[buffer(0)]],
                               device uint* outIndices [[buffer(1)]],
                               device atomic_uint* outVertexCounter [[buffer(2)]],
                               constant MarchingCubesParams& params [[buffer(3)]],
                               uint3 cellCoord [[thread_position_in_grid]]) {
    if (cellCoord.x >= params.cells.x || cellCoord.y >= params.cells.y || cellCoord.z >= params.cells.z) {
        return;
    }
    
    const int3 cornerOffsets[8] = {
        int3(0,0,0), int3(1,0,0), int3(1,1,0), int3(0,1,0),
        int3(0,0,1), int3(1,0,1), int3(1,1,1), int3(0,1,1)
    };
    
    const int2 edgeCornerIndexPairs[12] = {
        int2(0,1), int2(1,2), int2(2,3), int2(3,0),
        int2(4,5), int2(5,6), int2(6,7), int2(7,4),
        int2(0,4), int2(1,5), int2(2,6), int2(3,7)
    };
    
    const float3 cellOriginWS = params.origin + float3(cellCoord) * params.cellSize;
    
    float cornerScalar[8];
    float3 cornerPositionWS[8];
    
    for (int i = 0; i < 8; i++) {
        float3 cp = cellOriginWS + float3(cornerOffsets[i]) * params.cellSize;
        cornerPositionWS[i] = cp;
        cornerScalar[i] = sdf_sphere(cp, params.center, params.radius);
    }
    
    int cubeIndex = 0;
    if (cornerScalar[0] > params.isoLevel) cubeIndex |= 1;
    if (cornerScalar[1] > params.isoLevel) cubeIndex |= 2;
    if (cornerScalar[2] > params.isoLevel) cubeIndex |= 4;
    if (cornerScalar[3] > params.isoLevel) cubeIndex |= 8;
    if (cornerScalar[4] > params.isoLevel) cubeIndex |= 16;
    if (cornerScalar[5] > params.isoLevel) cubeIndex |= 32;
    if (cornerScalar[6] > params.isoLevel) cubeIndex |= 64;
    if (cornerScalar[7] > params.isoLevel) cubeIndex |= 128;
    
    int edgeMask = edgeTable[cubeIndex];
    if (edgeMask == 0) return;
    
    float3 edgeIntersectionWS[12];
    for (int edge = 0; edge < 12; ++edge) {
        if (edgeMask && (1 << edge)) {
            const int a = edgeCornerIndexPairs[edge].x;
            const int b = edgeCornerIndexPairs[edge].y;
            edgeIntersectionWS[edge] = interpolateIsoSurfacePosition(
                                                                     cornerPositionWS[a], cornerScalar[a],
                                                                     cornerPositionWS[b], cornerScalar[b],
                                                                     params.isoLevel
                                                                     );
        }
    }
    
    constant int* triangleEdgesRow = &triTable[cubeIndex][0];
    
    for (int triIdx = 0; triIdx < 16 && triangleEdgesRow[triIdx] != -1; triIdx += 3) {
        const int e0 = triangleEdgesRow[triIdx + 0];
        const int e1 = triangleEdgesRow[triIdx + 1];
        const int e2 = triangleEdgesRow[triIdx + 2];
        
        const float3 p0 = edgeIntersectionWS[e0];
        const float3 p1 = edgeIntersectionWS[e1];
        const float3 p2 = edgeIntersectionWS[e2];
        
        const float3 n0 = estimateNormalFromField(p0, params);
        const float3 n1 = estimateNormalFromField(p1, params);
        const float3 n2 = estimateNormalFromField(p2, params);
        
        const uint baseVertexIndex = atomic_fetch_add_explicit(outVertexCounter, (uint)3, memory_order_relaxed);
        
        outVertices[baseVertexIndex + 0].position = p0;
        outVertices[baseVertexIndex + 0].normal   = n0;
        outVertices[baseVertexIndex + 1].position = p1;
        outVertices[baseVertexIndex + 1].normal   = n1;
        outVertices[baseVertexIndex + 2].position = p2;
        outVertices[baseVertexIndex + 2].normal   = n2;
        
        outIndices[baseVertexIndex + 0] = baseVertexIndex + 0;
        outIndices[baseVertexIndex + 1] = baseVertexIndex + 1;
        outIndices[baseVertexIndex + 2] = baseVertexIndex + 2;
    }
};

