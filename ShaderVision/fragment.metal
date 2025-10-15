fragment float4 fragmentShader(
    ColorInOut vertexIn [[stage_in]],
    float2 pointCoord [[point_coord]],
    constant UniformsFrame &uniforms [[buffer(0)]])
{
    float d = length(pointCoord - float2(0.5));
    if (d > 0.5) {
        discard_fragment();
    }
    float3 nnorm = (vertexIn.normal + 1.0) / 2.0;
    float4 color = float4(
        (1.0 - d) * cnoise(nnorm.x * uniforms.time),
        (1.0 - d) * cnoise(nnorm.y * uniforms.time),
        (1.0 - d) * cnoise(nnorm.z * uniforms.time),
        1.0
    );
    return float4(color);
}