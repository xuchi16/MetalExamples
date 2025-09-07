#pragma once

#include <simd/simd.h>

struct MeshParams {
    simd_uint2 dimensions;
    simd_float2 size;
    float maxVertexDepth;
};
