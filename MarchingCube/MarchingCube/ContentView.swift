// Created by Chester for MarchingCube in 2025

import RealityKit
import RealityKitContent
import SwiftUI

struct ContentView: View {
    @State private var entity: Entity?
    @State private var mesh: LowLevelMesh?
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let computePipelineState: MTLComputePipelineState
    let vertexCountBuffer: MTLBuffer // TODO: vertexCountBuffer是干啥的
    
    let radius: Float = 0.175
    var cellsPerAxis: UInt32 = 80
    var cells: SIMD3<UInt32> {
        return SIMD3<UInt32>(cellsPerAxis, cellsPerAxis, cellsPerAxis)
    }

    var cellSize: SIMD3<Float> {
        let ratio = radius / Float(cellsPerAxis) * 2
        return SIMD3<Float>(ratio, ratio, ratio)
    }
    
    var material: PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.roughness = .init(floatLiteral: 0.0)
        m.metallic = .init(floatLiteral: 1.0)
        return m
    }
    
    init() {
        let device = MTLCreateSystemDefaultDevice()!
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        let library = device.makeDefaultLibrary()!
        let function = library.makeFunction(name: "marchingCubesShape")!
        self.computePipelineState = try! device.makeComputePipelineState(function: function)
        self.vertexCountBuffer = device.makeBuffer(length: MemoryLayout<UInt32>.stride, options: .storageModeShared)!
    }
    
    var body: some View {
        RealityView { content in
            let maxCellCount = Int(cells.x * cells.y * cells.z)
            let vertexCapacity = 15 * maxCellCount // TODO: 为啥这里是15没懂
            let indexCapacity = vertexCapacity
            
            let lowLevelMesh = try! VertexData.initMesh(
                vertexCapacity: vertexCapacity,
                indexCapacity: indexCapacity
            )
            let meshResource = try! await MeshResource(from: lowLevelMesh)
            let entity = ModelEntity(mesh: meshResource,
                                     materials: [material])
            content.add(entity)
            self.mesh = lowLevelMesh
            self.entity = entity
            updateMesh()
        }
    }
    
    func updateMesh() {
        guard let mesh = mesh,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        else {
            return
        }
        
        let gridSizeWorldSpace = SIMD3<Float>(Float(cells.x), Float(cells.y), Float(cells.z)) * cellSize
        let gridMinCornerWorldSpace = -0.5 * gridSizeWorldSpace
        let gridMaxCornerWorldSpace = gridMinCornerWorldSpace + gridSizeWorldSpace
        
        // TODO: 提供需要的具体参数
        var params = MarchingCubesParams(
            cells: cells,
            origin: gridMinCornerWorldSpace,
            cellSize: cellSize,
            isoLevel: 0.0,
            center: SIMD3<Float>(0, 0, 0),
            radius: radius,
        )
        
        vertexCountBuffer.contents().bindMemory(to: UInt32.self, capacity: 1).pointee = 0

        let vertexBuffer = mesh.replace(bufferIndex: 0, using: commandBuffer)
        let indexBuffer = mesh.replaceIndices(using: commandBuffer)
        
        computeEncoder.setComputePipelineState(computePipelineState)
        computeEncoder.setBuffer(vertexBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(indexBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(vertexCountBuffer, offset: 0, index: 2)
        computeEncoder.setBytes(&params, length: MemoryLayout<MarchingCubesParams>.stride, index: 3)
        
        let threadsPerThreadgroup = MTLSize(width: 8, height: 8, depth: 4)
        let threadgroups = MTLSize(
            width: (Int(cells.x) + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
            height: (Int(cells.y) + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
            depth: (Int(cells.z) + threadsPerThreadgroup.depth - 1) / threadsPerThreadgroup.depth
        )
        
        computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let vertexCount = Int(vertexCountBuffer.contents().bindMemory(to: UInt32.self, capacity: 1).pointee)
        mesh.parts.replaceAll([
            LowLevelMesh.Part(indexCount: vertexCount,
                              topology: .triangle,
                              bounds: BoundingBox(min: gridMinCornerWorldSpace, max: gridMaxCornerWorldSpace))
        ])
    }
}
