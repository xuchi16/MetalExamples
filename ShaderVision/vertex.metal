typedef struct
{
    float4 position [[position]];
    float3 normal;
    float  pointSize [[point_size]];
} ColorInOut;

vertex ColorInOut vertexShader(
    Vertex vertexIn                  [[stage_in]],
    ushort amp_id                    [[amplification_id]],
    unsigned int iid                 [[instance_id]],
    constant UniformsFrame &uniforms [[buffer(3)]])
{
    // Retrieve the environment mesh world matrix.
    float4x4 model = uniforms.environmentMeshWorld;

    // Apply MVP and pass along normals for coloring.
    UniformsCamera camera = uniforms.eyes[amp_id];
    float4 position = float4(vertexIn.position, 1.0);
    float4x4 viewProjection = camera.projection * camera.view;

    float pz = clamp(0.0, 20.0, abs(tan((cnoise(vertexIn.position.xyz) + uniforms.time * 0.5))));
    float3 newPos = position.xyz + pz * 0.005 * vertexIn.normal;
  
    ColorInOut vertexOut;
    vertexOut.position = viewProjection * model * float4(newPos, 1.0);
    vertexOut.normal = vertexIn.normal;
    vertexOut.pointSize = pz;
    return vertexOut;
}