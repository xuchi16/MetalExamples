// Created by Chester for MarchingCube in 2025

#ifndef MarchingCubesParams_h
#define MarchingCubesParams_h

#include <simd/simd.h>

struct MarchingCubesParams {
    simd_uint3  cells;
    simd_float3 origin;
    simd_float3 cellSize;
    float       isoLevel;
    simd_float3 center;
    float       radius;
};

#endif /* MarchingCubesParams_h */
