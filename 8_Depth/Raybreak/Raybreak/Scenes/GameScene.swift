// Created by Chester for Raybreak in 2025

import Foundation
import MetalKit

class GameScene: Scene {
    var quad: Plane
    var cube: Cube

    override init(device: MTLDevice, size: CGSize) {
        quad = Plane(device: device, imageName: "cloudy.png")
        cube = Cube(device: device)

        super.init(device: device, size: size)
        add(childNode: cube)
        add(childNode: quad)

        quad.position.z = -3
        quad.position.y = -1.5
    }

    override func update(deltaTime: Float) {
        cube.rotation.y += deltaTime
    }
}
