// Created by Chester for Raybreak in 2025

import Foundation
import MetalKit

class GameScene: Scene {
    var quad: Plane

    override init(device: MTLDevice, size: CGSize) {
        quad = Plane(device: device, imageName: "cloudy.png")

        super.init(device: device, size: size)
        add(childNode: quad)
    }
}
