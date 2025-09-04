// Created by Chester for LowLevelMeshPlane in 2025

import Foundation
import Metal
import RealityKit

struct PlaneMesh {
    var mesh: LowLevelMesh!
    
    // 平面大小
    let size: SIMD2<Float>
    // 每边点数量
    let dimensions: SIMD2<UInt32>
    
    let maxVertexDepth: Float
    
    init(size: SIMD2<Float>, dimensions: SIMD2<UInt32>, maxVertexDepth: Float = 1) {
        self.size = size
        self.dimensions = dimensions
        self.maxVertexDepth = maxVertexDepth
        
        self.mesh = try? createMesh()
        
        initVertexData()
        initIndexData()
        initMeshParts()
    }
    
    private func createMesh() throws -> LowLevelMesh {
        let positionAttributeOffset = MemoryLayout.offset(of: \PlaneVertex.position) ?? 0
        let normalAttributeOffset = MemoryLayout.offset(of: \PlaneVertex.normal) ?? 16
        
        let positionAttribute = LowLevelMesh.Attribute(semantic: .position,
                                                       format: .float3,
                                                       offset: positionAttributeOffset)
        let normalAttribute = LowLevelMesh.Attribute(semantic: .normal,
                                                     format: .float3,
                                                     offset: normalAttributeOffset)
        
        let vertexAttributes = [positionAttribute, normalAttribute]
        
        let vertexLayouts = [LowLevelMesh.Layout(bufferIndex: 0, bufferStride: MemoryLayout<PlaneVertex>.stride)]
        
        let vertexCount = Int(dimensions.x * dimensions.y)
        let indicesPerTriangle = 3
        let trianglePerCell = 2
        let cellCount = Int((dimensions.x - 1) * (dimensions.y - 1))
        let indicesCount = indicesPerTriangle * trianglePerCell * cellCount
        
        let meshDescriptor = LowLevelMesh.Descriptor(vertexCapacity: vertexCount,
                                                     vertexAttributes: vertexAttributes,
                                                     vertexLayouts: vertexLayouts,
                                                     indexCapacity: indicesCount)
        
        return try LowLevelMesh(descriptor: meshDescriptor)
    }
    
    private func initVertexData() {
        mesh.withUnsafeMutableBytes(bufferIndex: 0) { rawBytes in
            // 将物理地址转换成 PlaneVertex 的指针
            let vertices = rawBytes.bindMemory(to: PlaneVertex.self)
            let normalDirections: SIMD3<Float> = [0, 0, 1]
            
            for xCoord in 0..<dimensions.x {
                for yCoord in 0..<dimensions.y {
                    let xCoord01 = Float(xCoord) / Float(dimensions.x - 1)
                    let yCoord01 = Float(yCoord) / Float(dimensions.y - 1)
                    
                    let xPosition = size.x * xCoord01 - size.x / 2
                    let yPosition = size.y * yCoord01 - size.y / 2
                    let zPosition = Float(0)
                    
                    let vertexIndex = Int(vertexIndex(xCoord, yCoord))
                    vertices[vertexIndex].position = [xPosition, yPosition, zPosition]
                    vertices[vertexIndex].normal = normalDirections
                }
            }
        }
    }
    
    private func initIndexData() {
        mesh.withUnsafeMutableIndices { rawIndices in
            // 将物理地址转换成 UInt32 的指针
            guard var indices = rawIndices.baseAddress?.assumingMemoryBound(to: UInt32.self) else { return }
            
            // 循环所有的格子
            for xCoord in 0..<dimensions.x - 1 {
                for yCoord in 0..<dimensions.y - 1 {
                    /*
                       Each cell in the plane mesh consists of two triangles:
                                        
                                  topLeft     topRight
                                         |\ ̅ ̅|
                         1st Triangle--> | \ | <-- 2nd Triangle
                                         | ̲ ̲\|
                      +y       bottomLeft     bottomRight
                       ^
                       |
                       *---> +x
                                     
                     */
                    let bottomLeft = vertexIndex(xCoord, yCoord)
                    let bottomRight = vertexIndex(xCoord + 1, yCoord)
                    let topLeft = vertexIndex(xCoord, yCoord + 1)
                    let topRight = vertexIndex(xCoord + 1, yCoord + 1)
                    
                    indices[0] = bottomLeft
                    indices[1] = bottomRight
                    indices[2] = topLeft
                    
                    indices[3] = topLeft
                    indices[4] = bottomRight
                    indices[5] = topRight
                    
                    indices += 6
                }
            }
        }
    }

    private func initMeshParts() {
        let bounds = BoundingBox(min: [-size.x / 2, -size.y / 2, 0],
                                 max: [size.x / 2, size.y / 2, maxVertexDepth])
        
        mesh.parts.replaceAll([
            LowLevelMesh.Part(indexCount: mesh.descriptor.indexCapacity, topology: .triangle, bounds: bounds)
        ])
    }
    
    private func vertexIndex(_ xCoord: UInt32, _ yCoord: UInt32) -> UInt32 {
        return xCoord + dimensions.x * yCoord
    }
}
