// Created by Chester for Raybreak in 2025

import MetalKit

class Scene: Node {
    var device: MTLDevice
    var size: CGSize
    var camera = Camera()
    var sceneConstants = SceneConstants()

    init(device: MTLDevice, size: CGSize) {
        self.device = device
        self.size = size
        super.init()
        camera.aspect = Float(size.width / size.height)
        add(childNode: camera)
    }

    func update(deltaTime: Float) {}

    func render(commandEncoder: MTLRenderCommandEncoder,
                deltaTime: Float)
    {
        update(deltaTime: deltaTime)
        sceneConstants.projectionMatrix = camera.projectionMatrix
        commandEncoder.setVertexBytes(&sceneConstants,
                                      length: MemoryLayout<SceneConstants>.stride,
                                      index: 2)
        for child in children {
            child.render(commandEncoder: commandEncoder,
                         parentModelViewMatrix: camera.viewMatrix)
        }
    }
}
