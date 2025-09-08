// Created by Chester for MetalCubeExample in 2025

#ifndef CubeShaderTypes_h
#define CubeShaderTypes_h

#include <simd/simd.h>

struct CubeVertex {
    vector_float3 position;
    vector_float3 normal;
};

struct CubeParams {
    vector_float3 size;
    uint32_t dimensions_x;
    uint32_t dimensions_y;
    float cubeSphereInterpolationRatio;
};

#endif /* CubeShaderTypes_h */
