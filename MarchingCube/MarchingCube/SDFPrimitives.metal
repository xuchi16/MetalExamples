// Created by Chester for MarchingCube in 2025

#include <metal_stdlib>
using namespace metal;

#define SDFShapeTypeSphere      0u
#define SDFShapeTypeBox         1u
#define SDFShapeTypeTorus       2u
#define SDFShapeTypeRoundedBox  3u
#define SDFShapeTypeBoxFrame    4u
#define SDFShapeTypeLink        5u
#define SDFShapeTypeOctahedron  6u

inline float sdf_sphere(float3 p, float3 c, float r) {
    return length(p - c) - r;
}


inline float sdf_box(float3 p, float3 c, float3 b) {
    float3 d = abs(p - c) - b;
    return length(max(d, float3(0.0))) + min(max(d.x, max(d.y, d.z)), 0.0);
}

inline float sdf_torus(float3 p, float3 c, float R, float r) {
    float3 q = p - c;
    float2 k = float2(length(q.xz) - R, q.y);
    return length(k) - r;
}

inline float sdf_rounded_box(float3 p, float3 c, float3 b, float cr) {
    float3 q = abs(p - c) - (b - cr);
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - cr;
}

inline float sdf_box_frame(float3 p, float3 c, float3 b, float e) {
    float3 pp = abs(p - c) - b;
    float3 q  = abs(pp + e) - e;

    float3 v1 = float3(pp.x, q.y,  q.z);
    float3 v2 = float3(q.x,  pp.y, q.z);
    float3 v3 = float3(q.x,  q.y,  pp.z);

    float d1 = length(max(v1, 0.0)) + min(max(pp.x, max(q.y, q.z)), 0.0);
    float d2 = length(max(v2, 0.0)) + min(max(q.x,  max(pp.y, q.z)), 0.0);
    float d3 = length(max(v3, 0.0)) + min(max(q.x,  max(q.y,  pp.z)), 0.0);

    return min(min(d1, d2), d3);
}

inline float sdf_link(float3 p, float3 c, float le, float r1, float r2) {
    float3 q = float3(p.x - c.x, max(abs(p.y - c.y) - le, 0.0), p.z - c.z);
    return length(float2(length(q.xy) - r1, q.z)) - r2;
}

inline float sdf_octahedron(float3 p, float3 c, float s) {
    float3 pp = abs(p - c);
    return (pp.x + pp.y + pp.z - s) * 0.57735027; // 1/sqrt(3)
}

inline float sdf_for_shape(uint shapeType, float3 p, float3 center, float radius) {
    switch (shapeType) {
        default:
        case SDFShapeTypeSphere:
            return sdf_sphere(p, center, radius);
        case SDFShapeTypeBox: {
            float s = radius / sqrt(3.0f);
            return sdf_box(p, center, float3(s));
        }
        case SDFShapeTypeTorus: {
            float R = radius * 0.65f;
            float r = radius * 0.28f;
            return sdf_torus(p, center, R, r);
        }
        case SDFShapeTypeRoundedBox: {
            float s  = radius / sqrt(3.0f);
            float cr = s * 0.3f;
            return sdf_rounded_box(p, center, float3(s), cr);
        }
        case SDFShapeTypeBoxFrame: {
            float s = radius / sqrt(3.0f);
            float e = s * 0.20f;
            return sdf_box_frame(p, center, float3(s), e);
        }
        case SDFShapeTypeLink: {
            float le = radius * 0.25f;
            float r1 = radius * 0.6f;
            float r2 = radius * 0.15f;
            return sdf_link(p, center, le, r1, r2);
        }
        case SDFShapeTypeOctahedron: {
            float s = radius * 1.0f;
            return sdf_octahedron(p, center, s);
        }
    }
}
