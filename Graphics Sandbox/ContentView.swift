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
        mtkView.device = MTLCreateSystemDefaultDevice()!
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: NSViewRepresentableContext<MetalView>) {

    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalView
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState?
        let vertexBuffer: MTLBuffer
        
        init(_ parent: MetalView) {
            self.parent = parent
            self.device = MTLCreateSystemDefaultDevice()!
            self.commandQueue = device.makeCommandQueue()!
            let vertices = [Vertex2(color: [1, 0, 0, 1], pos: [-1, -1]),
                        Vertex2(color: [0, 1, 0, 1], pos: [0, 1]),
                        Vertex2(color: [0, 0, 1, 1], pos: [1, -1])]
            
            vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex2>.stride, options: [])!
            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            do {
                try self.pipelineState = MetalView.Coordinator.buildRenderPipelineWith(device: device, view: view)
            } catch {
                print("Unexpected error: \(error)")
            }
        }
        
        func draw(in view: MTKView) {
            let commandBuffer = commandQueue.makeCommandBuffer()
            let rpd = view.currentRenderPassDescriptor
            rpd?.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 1, 1)
            rpd?.colorAttachments[0].loadAction = .clear
            rpd?.colorAttachments[0].storeAction = .store
            
            let re = commandBuffer?.makeRenderCommandEncoder(descriptor: rpd!)
            re?.setRenderPipelineState(pipelineState!)
            re?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            re?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            re?.endEncoding()
            
            commandBuffer?.present(view.currentDrawable!)
            commandBuffer?.commit()
        }
        
        class func buildRenderPipelineWith(device: MTLDevice, view: MTKView) throws -> MTLRenderPipelineState {
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            let library = device.makeDefaultLibrary()
            pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertexShader")
            pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragmentShader")
            pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
    }
}
