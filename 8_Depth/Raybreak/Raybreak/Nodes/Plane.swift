// Created by Chester for Raybreak in 2025

import Foundation
import MetalKit

class Plane: Primitive {
    override func buildVertices() {
        vertices = [
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

        indices = [
            0, 1, 2,
            2, 3, 0,
        ]
    }
}
