// Created by Chester for InteractiveGeometry in 2025

import Foundation
import Metal

let metalDevice: MTLDevice? = MTLCreateSystemDefaultDevice()

func makeCommandQueue(labeled label: String) -> MTLCommandQueue? {
    guard let queue = metalDevice?.makeCommandQueue() else {
        print("Failed to make command queue")
        return nil
    }
    queue.label = label
    return queue
}

func makeComputePipeline(named name: String) -> MTLComputePipelineState? {
    guard let function = metalDevice?.makeDefaultLibrary()?.makeFunction(name: name) else {
        print("Failed to make pipeline")
        return nil
    }
    return try? metalDevice?.makeComputePipelineState(function: function)
}
