// Created by Chester for MarchingCube in 2025

import Foundation
import RealityKit
import MetalKit

extension VertexData {
    static var vertexAttributes: [LowLevelMesh.Attribute] = [
        .init(semantic: .position, format: .float3, offset: MemoryLayout<Self>.offset(of: \.position)!),
        .init(semantic: .normal, format: .float3, offset: MemoryLayout<Self>.offset(of: \.normal)!)
    ]
    
    static var vertexLayouts: [LowLevelMesh.Layout] = [
        .init(bufferIndex: 0, bufferStride: MemoryLayout<Self>.stride)
    ]
    
    static var descriptor: LowLevelMesh.Descriptor {
        var desc = LowLevelMesh.Descriptor()
        desc.vertexAttributes = Self.vertexAttributes
        desc.vertexLayouts = Self.vertexLayouts
        desc.indexType = .uint32
        return desc
    }
    
    @MainActor
    static func initMesh(vertexCapacity: Int, indexCapacity: Int) throws -> LowLevelMesh {
        var desc = Self.descriptor
        desc.vertexCapacity = vertexCapacity
        desc.indexCapacity = indexCapacity
        return try LowLevelMesh(descriptor: desc)
    }
}
