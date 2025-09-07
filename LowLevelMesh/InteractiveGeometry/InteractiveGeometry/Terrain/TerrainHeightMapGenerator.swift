// Created by Chester for InteractiveGeometry in 2025

import Metal
import MetalKit
import RealityKit

@MainActor
class TerrainHeightMapGenerator: HeightMapGenerator {
    private let resetPipeline: MTLComputePipelineState = makeComputePipeline(named: "resetTerrainHeightMap")!
    
    private let addHeightPipeline: MTLComputePipelineState = makeComputePipeline(named: "addHeightToTerrainHeightMap")!
    
    private var terrainTexture: MTLTexture? = nil
    private var brushTexture: MTLTexture? = nil
    private var resetTerrain: Bool = false
    
    init() {
        if let terrainTextureUrl = Bundle.main.url(forResource: "TerrainHeightMap", withExtension: "png") {
            terrainTexture = try? MTKTextureLoader(device: metalDevice.unsafelyUnwrapped)
                .newTexture(URL: terrainTextureUrl, options: nil)
        }
        
        if let brushTextureUrl = Bundle.main.url(forResource: "TerrainBrush", withExtension: "png") {
            brushTexture = try? MTKTextureLoader(device: metalDevice.unsafelyUnwrapped)
                .newTexture(URL: brushTextureUrl, options: nil)
        }
    }
    
    func reset() {
        resetTerrain = true
    }
    
    func generateHeightMap(
        computeContext: ComputeUpdateContext,
        heightMapTexture: LowLevelTexture,
        heightMapComputeParams: HeightMapComputeParams
    ) {
        var terrainParams = TerrainParams(
            brushPosition: simd_make_float2(heightMapComputeParams.interactionPosition),
            brushSize: 25 * heightMapComputeParams.cellSize.x,
            brushInfluence: 0.1 * Float(computeContext.deltaTime),
            dimensions: heightMapComputeParams.dimensions,
            size: heightMapComputeParams.size
        )
        
        if resetTerrain {
            computeContext.computeEncoder.setComputePipelineState(resetPipeline)
            computeContext.computeEncoder.setBytes(&terrainParams, length: MemoryLayout<TerrainParams>.size, index: 0)
            computeContext.computeEncoder.setTexture(terrainTexture, index: 1)
            computeContext.computeEncoder.setTexture(heightMapTexture.replace(using: computeContext.commandBuffer), index: 2)
            computeContext.computeEncoder.dispatchThreadgroups(heightMapComputeParams.threadgroups,
                                                               threadsPerThreadgroup: heightMapComputeParams.threadsPerThreadgroup)
            resetTerrain = false
        }
        
        // Add height with the height brush texture when an interaction is happening.
        if heightMapComputeParams.isInteractionHappening {
            computeContext.computeEncoder.setComputePipelineState(addHeightPipeline)
            computeContext.computeEncoder.setBytes(&terrainParams, length: MemoryLayout<TerrainParams>.size, index: 0)
            computeContext.computeEncoder.setTexture(brushTexture, index: 1)
            computeContext.computeEncoder.setTexture(heightMapTexture.read(), index: 2)
            computeContext.computeEncoder.setTexture(heightMapTexture.replace(using: computeContext.commandBuffer), index: 3)
            computeContext.computeEncoder.dispatchThreadgroups(heightMapComputeParams.threadgroups,
                                                               threadsPerThreadgroup: heightMapComputeParams.threadsPerThreadgroup)
        }
    }
}
