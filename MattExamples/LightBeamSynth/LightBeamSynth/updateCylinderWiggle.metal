#include <metal_stdlib>
using namespace metal;

struct VertexData {
    float3 position;
    float3 normal;
};

struct CylinderWiggleParams {
    int32_t radialSegments;
    int32_t heightSegments;
    float radius;
    float height;
    float animationProgress;
};

kernel void updateCylinderWiggle(device VertexData* vertices [[buffer(0)]],
                                 device uint* indices [[buffer(1)]],
                                 device float3* currentPositions [[buffer(2)]],
                                 device float3* targetPositions [[buffer(3)]],
                                 constant CylinderWiggleParams& params [[buffer(4)]],
                                 uint id [[thread_position_in_grid]])
{
    int x = id % (params.radialSegments + 1);
    int y = id / (params.radialSegments + 1);
    
    if (x > params.radialSegments || y > params.heightSegments) return;
    
    float angle = float(x) / float(params.radialSegments) * 2 * M_PI_F;
    
    float3 currentPosition = currentPositions[y];
    float3 targetPosition = targetPositions[y];
    float3 interpolatedPosition = mix(currentPosition, targetPosition, params.animationProgress);
    
    float3 position = interpolatedPosition + float3(cos(angle) * params.radius,
                                                    0,
                                                    sin(angle) * params.radius);
    
    float3 normal = normalize(float3(interpolatedPosition.x - position.x,
                                     0,
                                     interpolatedPosition.z - position.z));
    
    vertices[id].position = position;
    vertices[id].normal = normal;
    
    // Update indices
    if (x < params.radialSegments && y < params.heightSegments) {
        int indexBase = (y * params.radialSegments + x) * 6;
        uint32_t a = y * (params.radialSegments + 1) + x;
        uint32_t b = a + 1;
        uint32_t c = a + (params.radialSegments + 1);
        uint32_t d = c + 1;
        
        indices[indexBase] = a;
        indices[indexBase + 1] = b;
        indices[indexBase + 2] = d;
        indices[indexBase + 3] = a;
        indices[indexBase + 4] = d;
        indices[indexBase + 5] = c;
    }
}
