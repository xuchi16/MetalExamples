// Created by Chester for Raybreak in 2025

import Foundation
import MetalKit

class Plane: Node {
    var vertices: [Vertex] = [
        Vertex(position: [-1, 1, 0], // V0
               color: [1, 0, 0, 1],
               texture: [0, 1]),
        Vertex(position: [-1, -1, 0], // V1
               color: [0, 1, 0, 1],
               texture: [0, 0]),
        Vertex(position: [1, -1, 0], // V2
               color: [0, 0, 1, 1],
               texture: [1, 0]),
        Vertex(position: [1, 1, 0], // V3
               color: [1, 0, 1, 1],
               texture: [1, 1]),
    ]

    var indices: [UInt16] = [
        0, 1, 2,
        2, 3, 0,
    ]

    var vertexBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?

    var time: Float = 9

    struct Constants {
        var animatedBy: Float = 0.0
    }

    var constants = Constants()

    // Renderable
    var pipelineState: MTLRenderPipelineState!
    var fragmentFunctionName: String = "fragment_shader"
    var vertexFunctionName: String = "vertex_shader"
    var vertexDescriptor: MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()

        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0

        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD3<Float>>.stride + MemoryLayout<SIMD4<Float>>.stride
        vertexDescriptor.attributes[2].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        return vertexDescriptor
    }

    // Texturable
    var texture: MTLTexture?

    init(device: MTLDevice) {
        super.init()
        buildBuffers(device: device)
        pipelineState = buildPipelineState(device: device)
    }

    init(device: MTLDevice, imageName: String) {
        super.init()

        if let texture = setTexture(device: device, imageName: imageName) {
            self.texture = texture
            fragmentFunctionName = "textured_fragment"
        }
        buildBuffers(device: device)
        pipelineState = buildPipelineState(device: device)
    }

    private func buildBuffers(device: MTLDevice) {
        vertexBuffer = device.makeBuffer(bytes: vertices,
                                         length: vertices.count * MemoryLayout<Vertex>.stride,
                                         options: [])
        indexBuffer = device.makeBuffer(bytes: indices,
                                        length: indices.count * MemoryLayout<UInt16>.size,
                                        options: [])
    }

    override func render(commandEncoder: any MTLRenderCommandEncoder, deltaTime: Float) {
        super.render(commandEncoder: commandEncoder, deltaTime: deltaTime)
        guard let vertexBuffer, let indexBuffer else {
            return
        }

        // 计时
        time += deltaTime

        // 动画
        let animateBy = abs(sin(time) / 2 + 0.5)
        constants.animatedBy = animateBy

        commandEncoder.setRenderPipelineState(pipelineState)
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBytes(&constants, length: MemoryLayout<Constants>.stride, index: 1)
        commandEncoder.setFragmentTexture(texture, index: 0)

        // 设置绘制三角形的命令
        commandEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: indices.count,
            indexType: .uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0)
    }
}

extension Plane: Renderable {}

extension Plane: Texturable {}
