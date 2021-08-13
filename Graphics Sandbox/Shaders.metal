//
//  Shaders.metal
//  Graphics Sandbox
//
//  Created by Jeffrey Rogers on 8/10/21.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position  [[attribute(0)]];
    float3 normal    [[attribute(1)]];
    float2 texCoords [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 eyeNormal;
    float4 eyePosition;
    float2 texCoords;
};

struct Uniforms {
    float4x4 MVMatrix;
    float4x4 PMatrix;
};

vertex VertexOut vertexShader(VertexIn in [[stage_in]], constant Uniforms &uniforms [[buffer(1)]])
{
    VertexOut out;
    out.texCoords = in.texCoords;
    out.position = uniforms.PMatrix * uniforms.MVMatrix * float4(in.position, 1);
    out.eyeNormal = uniforms.MVMatrix * float4(in.position, 0);
    out.eyePosition = uniforms.MVMatrix * float4(in.normal, 1);
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]])
{
    return float4(1, 0, 0, 1);
}
