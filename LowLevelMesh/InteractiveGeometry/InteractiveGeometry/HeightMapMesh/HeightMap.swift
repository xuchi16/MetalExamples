// Created by Chester for InteractiveGeometry in 2025

import Foundation
import Metal
import RealityKit

@MainActor
struct HeightMap {
    /// 根据 shader function `deriveNormalsFromHeightMap` 来生成的 compute pipeline
    private let deriveNormalsPipeline: MTLComputePipelineState = makeComputePipeline(named: "deriveNormalsFromHeightMap")!

    var heightMapGenerator: HeightMapGenerator = SineWaveHeightMapGenerator()

    // 保存高度和法线信息
    var heightMapTexture: LowLevelTexture

    init(dimensions: SIMD2<UInt32>) throws {
        // 初始化 RGBA texture，其中 alpha 通道存储高度，RGB 存储法线信息
        let textureDescriptor = LowLevelTexture.Descriptor(pixelFormat: .rgba32Float,
                                                           width: Int(dimensions.x),
                                                           height: Int(dimensions.y),
                                                           textureUsage: [.shaderRead, .shaderWrite])
        self.heightMapTexture = try LowLevelTexture(descriptor: textureDescriptor)
    }

    func generateHeight(computeContext: ComputeUpdateContext,
                        heightMapComputeParams: HeightMapComputeParams)
    {
        heightMapGenerator
            .generateHeightMap(
                computeContext: computeContext,
                heightMapTexture: heightMapTexture,
                heightMapComputeParams: heightMapComputeParams
            )
    }

    func updateNormals(computeContext: ComputeUpdateContext,
                       heightMapComputeParams: HeightMapComputeParams) {
        let commandBuffer = computeContext.commandBuffer
        let computeEncoder = computeContext.computeEncoder
        
        let threadgroups = heightMapComputeParams.threadgroups
        let threadsPerThreadGroup = heightMapComputeParams.threadsPerThreadgroup
        
        var cellSize = heightMapComputeParams.cellSize
        
        computeEncoder.setComputePipelineState(deriveNormalsPipeline)
        
        // Pass a readable version of the height map texture to the compute shader.
        computeEncoder.setTexture(heightMapTexture.read(), index: 0)
        // Pass a writable version of the height map texture to the compute shader.
        computeEncoder.setTexture(heightMapTexture.replace(using: commandBuffer), index: 1)
        // Pass the cell size to the compute shader.
        computeEncoder.setBytes(&cellSize, length: MemoryLayout<SIMD2<Float>>.size, index: 2)
        
        // Dispatch the compute shader.
        computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadGroup)
    }
}
