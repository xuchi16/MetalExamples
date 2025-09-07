// Created by Chester for InteractiveGeometry in 2025

import Metal
import RealityKit

struct HeightMapComputeParams {
    let threadgroups: MTLSize
    let threadsPerThreadgroup: MTLSize
    let dimensions: SIMD2<UInt32>
    let size: SIMD2<Float>
    let cellSize: SIMD2<Float>
    let isInteractionHappening: Bool
    let interactionPosition: SIMD3<Float>
}

class HeightMapMesh: ComputeSystem {
    var isInteractionHappening: Bool = false
    var interactionPosition: SIMD3<Float> = [0, 0, 0]

    private let setVerticesPipeline: MTLComputePipelineState = makeComputePipeline(named: "setVertexData")!

    let dimensions: SIMD2<UInt32>
    let size: SIMD2<Float>
    let cellSize: SIMD2<Float>

    var planeMesh: PlaneMesh
    var heightMap: HeightMap

    private var meshParams: MeshParams
    private let threadgroups: MTLSize
    private let threadsPerThreadgroup: MTLSize

    init(size: SIMD2<Float>, dimensions: SIMD2<UInt32>, maxVertexDepth: Float) throws {
        assert(dimensions.x >= 2 && dimensions.y >= 2, "Height map mesh must have at least 2 vertices/pixels in each dimension.")
        self.dimensions = dimensions
        self.size = size
        self.cellSize = SIMD2<Float>(size.x / Float(dimensions.x - 1),
                                     size.y / Float(dimensions.y - 1))

        // Create the plane mesh and height map.
        self.planeMesh = PlaneMesh(size: size, dimensions: dimensions, maxVertexDepth: maxVertexDepth)
        self.heightMap = try HeightMap(dimensions: dimensions)

        // Initialize the mesh parameters structure.
        self.meshParams = MeshParams(dimensions: dimensions, size: size, maxVertexDepth: maxVertexDepth)

        // Calculate the number of threadgroups to dispatch.
        // 这里从 setVerticesPipeline 获取的是硬件优化建议值
        // 这里在计算每一组用多少 threads，按照系统推荐值拉满，行程一个合理的形状，比如 32 x 16 x 1
        // 其中 Width=32 是系统 SIMD 宽度，Height=16 是根据系统最大容纳的线程数量除以 Width 得来
        let threadWidth = setVerticesPipeline.threadExecutionWidth
        let threadHeight = setVerticesPipeline.maxTotalThreadsPerThreadgroup / threadWidth
        self.threadsPerThreadgroup = MTLSize(width: threadWidth, height: threadHeight, depth: 1)
        // 向上取整
        self.threadgroups = MTLSize(width: (Int(dimensions.x) + threadWidth - 1) / threadWidth,
                                    height: (Int(dimensions.y) + threadHeight - 1) / threadHeight,
                                    depth: 1)
    }

    func update(computeContext: ComputeUpdateContext) {
        let heightMapComputeParams = HeightMapComputeParams(threadgroups: threadgroups,
                                                            threadsPerThreadgroup: threadsPerThreadgroup,
                                                            dimensions: dimensions,
                                                            size: size,
                                                            cellSize: cellSize,
                                                            isInteractionHappening: isInteractionHappening,
                                                            interactionPosition: interactionPosition)

        heightMap.generateHeight(computeContext: computeContext,
                                 heightMapComputeParams: heightMapComputeParams)
        heightMap.updateNormals(computeContext: computeContext,
                                heightMapComputeParams: heightMapComputeParams)

        updateVertices(computeContext: computeContext)
    }

    private func updateVertices(computeContext: ComputeUpdateContext) {
        computeContext.computeEncoder.setComputePipelineState(setVerticesPipeline)
        computeContext.computeEncoder.setBytes(&meshParams, length: MemoryLayout<MeshParams>.size,
                                               index: 0)
        /***
         在当前 GPU 命令缓冲区执行期间，安全地替换网格中指定索引的缓冲区内容，并返回一个可供 CPU 写入的新缓冲区。
         replace: 如果 GPU 正在读取缓冲区A来渲染上一帧，而 CPU 同时写入缓冲区A来准备下一帧，会导致数据竞争和渲染错误。
         replace 确保在 GPU 使用完当前缓冲区之前，不会让 CPU 修改它。
         - replace 内部维护着一个缓冲区池（比如2-3个缓冲区）
         - 每次调用时，它返回一个当前未被 GPU 使用的缓冲区给 CPU
         - GPU 继续使用之前分配的缓冲区完成当前帧的渲染
         
         using: computeContext.commandBuffer
         这个参数告诉 replace 方法："这个替换操作与当前正在录制的命令缓冲区相关联。只有当这个命令缓冲区执行完成（即GPU处理完当前帧）后，你才可以在未来的帧中重用我现在正在替换的这个缓冲区。"
         */
        let vertexBuffer = planeMesh.mesh.replace(bufferIndex: 0, using: computeContext.commandBuffer)
        computeContext.computeEncoder.setBuffer(vertexBuffer, offset: 0, index: 1)
        computeContext.computeEncoder.setTexture(heightMap.heightMapTexture.read(), index: 2)
        computeContext.computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
    }
}
