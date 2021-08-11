//
//  ShaderDefinitions.h
//  Graphics Sandbox
//
//  Created by Jeffrey Rogers on 8/10/21.
//

#ifndef ShaderDefinitions_h
#define ShaderDefinitions_h

#include <simd/simd.h>

struct Vertex2 {
    vector_float4 color;
    vector_float2 pos;
};

struct Vertex3 {
    vector_float4 color;
    vector_float3 pos;
};

#endif /* ShaderDefinitions_h */
