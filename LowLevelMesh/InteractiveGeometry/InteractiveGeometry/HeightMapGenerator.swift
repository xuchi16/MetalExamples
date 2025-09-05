// Created by Chester for InteractiveGeometry in 2025

import Metal
import RealityKit

@MainActor
protocol HeightMapGenerator {
    /// Resets the height map.
    func reset()

    /// Generates the height map.
    func generateHeightMap()
//    func generateHeightMap(computeContext: ComputeUpdateContext,
//                           heightMapTexture: LowLevelTexture,
//                           heightMapComputeParams: HeightMapComputeParams)
}
