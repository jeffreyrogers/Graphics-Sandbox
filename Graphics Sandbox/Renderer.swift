//
//  Renderer.swift
//  Graphics Sandbox
//
//  Created by Jeffrey Rogers on 8/12/21.
//

import MetalKit
import simd

class Renderer: NSObject, MTKViewDelegate {
    var parent: MetalView
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState?
    var mouseLocation: NSPoint = NSPoint(x: 0, y: 0)
    var vertexDescriptor: MTLVertexDescriptor!
    var meshes: [MTKMesh] = []
    var time: Float = 0
    let depthStencilState: MTLDepthStencilState
    var tileTexture: MTLTexture?
    let samplerState: MTLSamplerState
    var uniforms = Uniforms()

    init(_ parent: MetalView) {
        self.parent = parent
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = device.makeCommandQueue()!

        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        self.depthStencilState = self.device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.normalizedCoordinates = true
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        self.samplerState = self.device.makeSamplerState(descriptor: samplerDescriptor)!
        
        super.init()
        loadTeapot()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        do {
            try self.pipelineState = self.buildRenderPipelineWith(device: device, view: view)
        } catch {
            fatalError("Could not create render pipeline state object: \(error)")
        }
        
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) {
            self.mouseLocation = $0.locationInWindow
            return $0
        }
        
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp]) {
            print("left mouse up")
            return $0
        }
        
        NSEvent.addLocalMonitorForEvents(matching: [.rightMouseUp]) {
            print("right mouse up")
            return $0
        }
        
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) {
            print("key \($0.charactersIgnoringModifiers ?? "")")
            
            if $0.modifierFlags.contains(.command) {
                if $0.characters?.contains("q") == true {
                    return $0
                }
            }
            
            return nil
        }
    }
    
    func loadTeapot() {
        let modelURL = Bundle.main.url(forResource: "teapot", withExtension: "obj")!
        let vd = MDLVertexDescriptor()
        
        // TODO: switch this to non-interleaved data
        vd.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        vd.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<Float>.size*3, bufferIndex: 0)
        vd.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: MemoryLayout<Float>.size*6, bufferIndex: 0)
        vd.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
        self.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vd)

        let ba = MTKMeshBufferAllocator(device: self.device)
        let teapot = MDLAsset(url: modelURL, vertexDescriptor: vd, bufferAllocator: ba)

        do {
            // first part contains the original teapot meshes, which we don't care about anymore so we ignore it
            (_, self.meshes) = try MTKMesh.newMeshes(asset: teapot, device: self.device)
        } catch {
            fatalError("Could not extract meshes from Model I/O asset")
        }
        
        let textureLoader = MTKTextureLoader(device: self.device)
        let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps: true, .SRGB: true]
        self.tileTexture = try? textureLoader.newTexture(name: "Tiles", scaleFactor: 1.0, bundle: nil, options: options)
    }

    func update(view: MTKView) {
        self.time += 1 / Float(view.preferredFramesPerSecond)
        let angle = -time
        let modelMatrix = float4x4(rotateAbout: SIMD3<Float>(0, 1, 1), by: angle) * float4x4(scaleBy: 2)
        let viewMatrix = float4x4(translateBy: SIMD3<Float>(0, 0, -2))
        let modelViewMatrix = viewMatrix * modelMatrix
        let aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)
        let projectionMatrix = float4x4(fov: Float.pi/3, aspectRatio: aspectRatio, nearZ: 0.1, farZ: 100)
        self.uniforms = Uniforms(modelViewMatrix: modelViewMatrix, projectionMatrix: projectionMatrix)
    }
    
    func process_input() {
        
    }

    func render(view: MTKView) {
        let commandBuffer = self.commandQueue.makeCommandBuffer()
        let rpd = view.currentRenderPassDescriptor
        rpd?.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        rpd?.colorAttachments[0].loadAction = .clear
        rpd?.colorAttachments[0].storeAction = .store
        
        let re = commandBuffer?.makeRenderCommandEncoder(descriptor: rpd!)
        re?.setRenderPipelineState(self.pipelineState!)
        re?.setVertexBytes(&self.uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        re?.setDepthStencilState(self.depthStencilState)
        re?.setFragmentTexture(self.tileTexture, index: 0)
        re?.setFragmentSamplerState(self.samplerState, index: 0)

        for mesh in self.meshes {
            let vertexBuffer = mesh.vertexBuffers.first!
            re?.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
            
            for submesh in mesh.submeshes {
                let indexBuffer = submesh.indexBuffer
                re?.drawIndexedPrimitives(type: submesh.primitiveType,
                                         indexCount: submesh.indexCount,
                                         indexType: submesh.indexType,
                                         indexBuffer: indexBuffer.buffer,
                                         indexBufferOffset: indexBuffer.offset
                )
            }
        }
        
        re?.endEncoding()
        commandBuffer?.present(view.currentDrawable!)
        commandBuffer?.commit()
    }
    
    // This is the game loop. It is called mtkView.preferredFramesPerSecond times per second
    func draw(in view: MTKView) {
        self.process_input()
        self.update(view: view)
        self.render(view: view)
    }
    
    func buildRenderPipelineWith(device: MTLDevice, view: MTKView) throws -> MTLRenderPipelineState {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        let library = device.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        pipelineDescriptor.vertexDescriptor = self.vertexDescriptor
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}

struct Uniforms {
    init() {
        MVMatrix = float4x4()
        PMatrix = float4x4()
    }
    
    init(modelViewMatrix: float4x4, projectionMatrix: float4x4) {
        MVMatrix = modelViewMatrix
        PMatrix = projectionMatrix
    }
    
    var MVMatrix: float4x4
    var PMatrix: float4x4
}
