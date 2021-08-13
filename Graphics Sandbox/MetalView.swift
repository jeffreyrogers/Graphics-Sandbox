//
//  MetalView.swift
//  Graphics Sandbox
//
//  Created by Jeffrey Rogers on 8/12/21.
//

import SwiftUI
import MetalKit

struct MetalView: NSViewRepresentable {
    func makeCoordinator() -> Renderer {
        Renderer(self)
    }
    
    func makeNSView(context: NSViewRepresentableContext<MetalView>) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.framebufferOnly = false
        mtkView.drawableSize = mtkView.frame.size
        mtkView.device = MTLCreateSystemDefaultDevice()! // try replacing this with context.coordinator.device so we only call this once
        mtkView.colorPixelFormat = .bgra8Unorm
//        mtkView.depthStencilPixelFormat = .depth32Float
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: NSViewRepresentableContext<MetalView>) {

    }
}
