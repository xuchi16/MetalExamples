// Created by Chester for Raybreak in 2025

import Foundation
import MetalKit

class Renderer: NSObject {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue

    var vertices: [Vertex] = [
        Vertex(position: [-1, 1, 0], color: [1, 0, 0, 1]), // V0
        Vertex(position: [-1, -1, 0], color: [0, 1, 0, 1]), // V1
        Vertex(position: [1, -1, 0], color: [0, 0, 1, 1]), // V2
        Vertex(position: [1, 1, 0], color: [1, 0, 1, 1]), // V3
    ]

    var indices: [UInt16] = [
        0, 1, 2,
        2, 3, 0,
    ]

    var pipelineState: MTLRenderPipelineState?
    var vertexBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?

    struct Constants {
        var animatedBy: Float = 0.0
    }

    var constants = Constants()
    var time: Float = 9

    init(device: MTLDevice) {
        self.device = device
        commandQueue = device.makeCommandQueue()!
        super.init()

        buildBuffers()
        buildPipelineState()
    }

    private func buildBuffers() {
        vertexBuffer = device.makeBuffer(bytes: vertices,
                                         length: vertices.count * MemoryLayout<Vertex>.stride,
                                         options: [])
        indexBuffer = device.makeBuffer(bytes: indices,
                                        length: indices.count * MemoryLayout<UInt16>.size,
                                        options: [])
    }

    private func buildPipelineState() {
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_shader")
        let fragmentFunction = library?.makeFunction(name: "fragment_shader")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // 定义 vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride

        pipelineDescriptor.vertexDescriptor = vertexDescriptor

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
              let vertexBuffer,
              let indexBuffer,
              let descriptor = view.currentRenderPassDescriptor
        else {
            return
        }

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }

        guard let commandEncooder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        // 计时
        time += 1 / Float(view.preferredFramesPerSecond)

        // 动画
        let animateBy = abs(sin(time) / 2 + 0.5)
        constants.animatedBy = animateBy

        // 设置绘制三角形的命令
        commandEncooder.setRenderPipelineState(pipelineState)
        commandEncooder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncooder.setVertexBytes(&constants, length: MemoryLayout<Constants>.stride, index: 1)

        commandEncooder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: indices.count,
            indexType: .uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0)

        // 真正绘制三角形
        commandEncooder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
