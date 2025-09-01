// Created by Chester for Raybreak in 2025

import Foundation
import MetalKit

class Renderer: NSObject {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue

    var vertices: [Float] = [
        0, 1, 0,
        -1, -1, 0,
        1, -1, 0
    ]

    var pipelineState: MTLRenderPipelineState?
    var vertexBuffer: MTLBuffer?

    init(device: MTLDevice) {
        self.device = device
        commandQueue = device.makeCommandQueue()!
        super.init()

        buildModel()
        buildPipelineState()
    }

    private func buildModel() {
        vertexBuffer = device.makeBuffer(bytes: vertices,
                                         length: vertices.count * MemoryLayout<Float>.size,
                                         options: [])
    }

    private func buildPipelineState() {
        let library = device.makeDefaultLibrary()
        let vertextFunction = library?.makeFunction(name: "vertex_shader")
        let fragmentFunction = library?.makeFunction(name: "fragment_shader")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertextFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        // 每一帧都会调用
        // 首先要获取到调用时的 drawable 和 descriptor
        guard let drawable = view.currentDrawable,
              let pipelineState,
              let descriptor = view.currentRenderPassDescriptor
        else {
            return
        }

        let commandBuffer = commandQueue.makeCommandBuffer()

        let commandEncooder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)

        // 设置绘制三角形的命令
        commandEncooder?.setRenderPipelineState(pipelineState)
        commandEncooder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncooder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)

        // 真正绘制三角形
        commandEncooder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
