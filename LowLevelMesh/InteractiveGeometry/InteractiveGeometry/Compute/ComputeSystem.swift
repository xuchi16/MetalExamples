// Created by Chester for InteractiveGeometry in 2025

import Metal
import RealityKit

/// A structure containing the context a `ComputeSystem` needs to dispatch compute commands in every frame.
struct ComputeUpdateContext {
    /// The number of seconds elapsed since the last frame.
    let deltaTime: TimeInterval
    /// The command buffer for the current frame.
    let commandBuffer: MTLCommandBuffer
    /// The compute command encoder for the current frame.
    let computeEncoder: MTLComputeCommandEncoder
}

protocol ComputeSystem {
    @MainActor
    func update(computeContext: ComputeUpdateContext)
}

// 每个组件包含自己对应的 ComputeSystem
struct ComputeSystemComponent: Component {
    let computeSystem: ComputeSystem
}

struct ComputeDispatchSystem: System {
    static let commandQueue: MTLCommandQueue? = makeCommandQueue(labeled: "Compute Dispatch System Command Queue")

    let query = EntityQuery(where: .has(ComputeSystemComponent.self))

    init(scene: Scene) {}
    
    func update(context: SceneUpdateContext) {
        let computeSystemEntities = context.entities(matching: query, updatingSystemWhen: .rendering)
        
        guard let commandBuffer = Self.commandQueue?.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        
        commandBuffer.enqueue()
        
        let computeContext = ComputeUpdateContext(
            deltaTime: context.deltaTime,
            commandBuffer: commandBuffer,
            computeEncoder: computeEncoder
        )
        
        for computeSystemEntity in computeSystemEntities {
            if let computeSystemComponent = computeSystemEntity.components[ComputeSystemComponent.self] {
                computeSystemComponent.computeSystem.update(computeContext: computeContext)
            }
        }
        
        computeEncoder.endEncoding()
        commandBuffer.commit()
    }
}
