// Created by Chester for InteractiveGeometry in 2025

import Foundation
import RealityKit
import Metal

@MainActor
protocol HeightMapGenerator {
    func reset()
    
    func generateHeightMap(computeContext: ComputeUpdateContext,
                           heightMapTexture: LowLevelTexture,
                           heightMapComputeParams: HeightMapComputeParams
    )
}
