// Created by Chester for Raybreak in 2025

import MetalKit

class Scene: Node {
    var device: MTLDevice
    var size: CGSize

    init(device: MTLDevice, size: CGSize) {
        self.device = device
        self.size = size
        super.init()
    }

    func update(deltaTime: Float) {}

    func render(commandEncoder: MTLRenderCommandEncoder,
                deltaTime: Float)
    {
        update(deltaTime: deltaTime)
        let viewMatrix = matrix_float4x4(translationX: 0, y: 0, z: -4)
        for child in children {
            child.render(commandEncoder: commandEncoder,
                         parentModelViewMatrix: viewMatrix)
        }
    }
}
