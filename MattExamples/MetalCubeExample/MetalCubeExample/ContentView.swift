// Created by Chester for MetalCubeExample in 2025

import RealityKit
import RealityKitContent
import SwiftUI

struct CubeSphereState {
    var size: SIMD3<Float> = [0.3, 0.3, 0.3]
    var planeResolution: SIMD2<UInt32> = [16, 16]
    var cubeSphereInterpolationRatio: Float = 0.0
}

struct ContentView: View {
    @State private var rootEntity: Entity?
    @State private var mesh: LowLevelMesh?
    @State var state: CubeSphereState = .init()
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let computePipeline: MTLComputePipelineState
        
    @State var isForward: Bool = true
    @State var time: Double = 0.0
    @State var timer: Timer?
    @State var deadBandValue: Double = 0.5
    @State private var rotationAngles: SIMD3<Float> = [0, 0, 0]
    @State private var lastRotationUpdateTime = CACurrentMediaTime()
        
    let deadbandStep = 0.005
    let modulationStep: Float = 0.02
    let maxResolution: UInt32 = 128

    init() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = device.makeCommandQueue()!
            
        let library = device.makeDefaultLibrary()!
        let updateFunction = library.makeFunction(name: "updateCubeMesh")!
        self.computePipeline = try! device.makeComputePipelineState(function: updateFunction)
    }
        
    var body: some View {
        RealityView { content in
            let mesh = try! createMesh()
            let resource = try! MeshResource(from: mesh)
            let modelComponent = ModelComponent(mesh: resource, materials: [UnlitMaterial()])
            let entity = Entity()
            entity.components.set(modelComponent)
            content.add(entity)
            self.mesh = mesh
            updateMesh(with: state)
            self.rootEntity = entity
        } update: { _ in
            updateMesh(with: state)
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }
        
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1 / 120.0, repeats: true) { _ in
                
            updateRotation()
                
            if deadBandValue > 0 {
                deadBandValue -= deadbandStep
                return
            }
                
            var ratio = state.cubeSphereInterpolationRatio
            if isForward {
                ratio += modulationStep
                if ratio >= 1.0 {
                    deadBandValue = 1.0
                    ratio = 1
                    isForward = false
                }
            } else {
                ratio -= modulationStep
                if ratio <= 0.0 {
                    deadBandValue = 1.0
                    ratio = 0.0
                    isForward = true
                }
            }
            state.cubeSphereInterpolationRatio = ratio
        }
    }
        
    func updateRotation() {
        let currentTime = CACurrentMediaTime()
        let frameDuration = currentTime - lastRotationUpdateTime
        time += frameDuration
            
        // Rotate along all axis at different rates for a wonky roll effect
        rotationAngles.x += Float(frameDuration * 0.25)
        rotationAngles.y += Float(frameDuration * 0.125)
        rotationAngles.z += Float(frameDuration * 0.0675)
            
        let rotationX = simd_quatf(angle: rotationAngles.x, axis: [1, 0, 0])
        let rotationY = simd_quatf(angle: rotationAngles.y, axis: [0, 1, 0])
        let rotationZ = simd_quatf(angle: rotationAngles.z, axis: [0, 0, 1])
        rootEntity?.transform.rotation = rotationX * rotationY * rotationZ
            
        lastRotationUpdateTime = currentTime
    }
        
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
        
    private var vertexCount: Int {
        Int(state.planeResolution.x * state.planeResolution.y * 6) // 6 faces
    }
        
    private var vertexCapacity: Int {
        Int(maxResolution * maxResolution * 6)
    }
        
    private var indexCount: Int {
        Int(6 * (state.planeResolution.x - 1) * (state.planeResolution.y - 1) * 6) // 6 indices per quad, 6 faces
    }
        
    private var indexCapacity: Int {
        Int(6 * (maxResolution - 1) * (maxResolution - 1) * 6) // 6 indices per quad, 6 faces
    }
        
    private func createMesh() throws -> LowLevelMesh {
        let vertexAttributes = [
            LowLevelMesh.Attribute(semantic: .position, format: .float3, offset: 0),
            LowLevelMesh.Attribute(semantic: .normal, format: .float3, offset: MemoryLayout<SIMD3<Float>>.stride)
        ]
            
        let vertexLayouts = [
            LowLevelMesh.Layout(bufferIndex: 0, bufferStride: MemoryLayout<CubeVertex>.stride)
        ]
            
        return try LowLevelMesh(descriptor: .init(
            vertexCapacity: vertexCapacity,
            vertexAttributes: vertexAttributes,
            vertexLayouts: vertexLayouts,
            indexCapacity: indexCapacity
        ))
    }
        
    private func updateMesh(with state: CubeSphereState) {
        guard let mesh = mesh,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
            
        var params = CubeParams(
            size: state.size,
            dimensions_x: UInt32(state.planeResolution.x),
            dimensions_y: UInt32(state.planeResolution.y),
            cubeSphereInterpolationRatio: state.cubeSphereInterpolationRatio
        )
            
        let vertexBuffer = mesh.replace(bufferIndex: 0, using: commandBuffer)
        let indexBuffer = mesh.replaceIndices(using: commandBuffer)
            
        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.setBuffer(vertexBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(indexBuffer, offset: 0, index: 1)
        computeEncoder.setBytes(&params, length: MemoryLayout<CubeParams>.stride, index: 2)
            
        let threadgroupSize = MTLSize(width: 64, height: 1, depth: 1)
        let threadgroups = MTLSize(
            width: (vertexCount + threadgroupSize.width - 1) / threadgroupSize.width,
            height: 1,
            depth: 1
        )
            
        computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)
        computeEncoder.endEncoding()
            
        commandBuffer.commit()
            
        let halfSize = state.size * 0.5
        let bounds = BoundingBox(
            min: -halfSize,
            max: halfSize
        )
            
        mesh.parts.replaceAll([
            LowLevelMesh.Part(
                indexCount: mesh.descriptor.indexCapacity,
                topology: .line,
                bounds: bounds
            )
        ])
    }
}
