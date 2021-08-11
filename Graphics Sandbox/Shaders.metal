//
//  Shaders.metal
//  Graphics Sandbox
//
//  Created by Jeffrey Rogers on 8/10/21.
//

#include <metal_stdlib>
#include "ShaderDefinitions.h"
using namespace metal;

struct VertexOut {
    float4 color;
    float4 pos [[position]];
};

vertex VertexOut vertexShader(const device Vertex2* vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]])
{
    VertexOut out;
    Vertex2 in = vertexArray[vid];
    out.color = in.color;
    out.pos = float4(in.pos.x, in.pos.y, 0, 1);
    return out;
}

fragment float4 fragmentShader(VertexOut interpolated [[stage_in]])
{
    return interpolated.color;
}
