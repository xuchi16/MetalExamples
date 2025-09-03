// Created by Chester for Raybreak in 2025

import Foundation
import MetalKit

class GameScene: Scene {
    let mushroom: Model

    override init(device: MTLDevice, size: CGSize) {
        mushroom = Model(device: device, modelName: "mushroom")
        super.init(device: device, size: size)

        add(childNode: mushroom)

        camera.position.z = -6
    }

    override func update(deltaTime: Float) {
        mushroom.rotation.y += deltaTime
    }
}
