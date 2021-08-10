//
//  ContentView.swift
//  Graphics Sandbox
//
//  Created by Jeffrey Rogers on 8/9/21.
//

import SwiftUI
import MetalKit

struct ContentView: View {
    var body: some View {
        MetalView().frame(width: 1200, height: 800)
    }
}

struct MetalView: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: NSViewRepresentableContext<MetalView>) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.drawableSize = mtkView.frame.size

        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: NSViewRepresentableContext<MetalView>) {

    }
    
    // TODO: rename this renderer, move out into its own class
    // TODO: add data, and process input
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalView
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        
        init(_ parent: MetalView) {
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.device = metalDevice
            }
            self.commandQueue = device.makeCommandQueue()!
            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

        }
        
        func draw(in view: MTKView) {
            let commandBuffer = commandQueue.makeCommandBuffer()
            let rpd = view.currentRenderPassDescriptor
            rpd?.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 1, 1)
            rpd?.colorAttachments[0].loadAction = .clear
            rpd?.colorAttachments[0].storeAction = .store
            
            let re = commandBuffer?.makeRenderCommandEncoder(descriptor: rpd!)
            re?.endEncoding()
            
            commandBuffer?.present(view.currentDrawable!)
            commandBuffer?.commit()
        }
    }
}
