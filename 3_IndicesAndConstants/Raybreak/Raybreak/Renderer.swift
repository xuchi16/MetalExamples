// Created by Chester for Raybreak in 2025

import Foundation
import MetalKit

class Renderer: NSObject {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue

    var vertices: [Float] = [
        -1, 1, 0, // V0
        -1, -1, 0, // V1
        1, -1, 0, // V2
        1, 1, 0 // V3
    ]

    var indices: [UInt16] = [
        0, 1, 2,
        2, 3, 0
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

        buildModel()
        buildPipelineState()
    }

    private func buildModel() {
        vertexBuffer = device.makeBuffer(bytes: vertices,
                                         length: vertices.count * MemoryLayout<Float>.size,
                                         options: [])
        indexBuffer = device.makeBuffer(bytes: indices,
                                        length: indices.count * MemoryLayout<UInt16>.size,
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
