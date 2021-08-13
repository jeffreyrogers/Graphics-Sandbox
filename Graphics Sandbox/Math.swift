//
//  Math.swift
//  Graphics Sandbox
//
//  Created by Jeffrey Rogers on 8/12/21.
//

import simd

extension float4x4 {
    init(scaleBy s: Float) {
        self.init(SIMD4<Float>(s, 0, 0, 0),
                  SIMD4<Float>(0, s, 0, 0),
                  SIMD4<Float>(0, 0, s, 0),
                  SIMD4<Float>(0, 0, 0, 1)
        )
    }

    init(rotateAbout axis: SIMD3<Float>, by radians: Float) {
        let x = axis.x, y = axis.y, z = axis.z
        let c = cosf(radians)
        let s = sinf(radians)
        let t = 1 - c
        self.init(SIMD4<Float>(t*x*x+c,   t*x*y+z*s, t*x*z-y*s, 0),
                  SIMD4<Float>(t*x*y-z*s, t*y*y+c,   t*y*z+x*s, 0),
                  SIMD4<Float>(t*x*z+y*s, t*y*z-x*s,   t*z*z+c, 0),
                  SIMD4<Float>(        0,         0,         0, 1)
        )
    }

    init(translateBy t: SIMD3<Float>) {
        self.init(SIMD4<Float>(  1,     0,    0, 0),
                  SIMD4<Float>(  0,     1,    0, 0),
                  SIMD4<Float>(  0,     0,    1, 0),
                  SIMD4<Float>(t[0], t[1], t[2], 1)
        )
    }

    init(fov radians: Float, aspectRatio: Float, nearZ: Float, farZ: Float) {
        let yScale = 1 / tan(radians * 0.5)
        let xScale = yScale / aspectRatio
        let zRange = farZ - nearZ
        let zScale = -(farZ + nearZ) / zRange
        let wzScale = -2 * farZ * nearZ / zRange

        let xx = xScale
        let yy = yScale
        let zz = zScale
        let zw = Float(-1)
        let wz = wzScale

        self.init(SIMD4<Float>(xx,  0,  0,  0),
                  SIMD4<Float>( 0, yy,  0,  0),
                  SIMD4<Float>( 0,  0, zz, zw),
                  SIMD4<Float>( 0,  0, wz,  1)
        )
    }
}
