import AVFoundation
import SwiftUI
import RealityKit

#Preview { LightBeamSynthView() }
struct LightBeamSynthView: View {
    @Environment(\.physicalMetrics) var physicalMetrics
    @State var outerCylinderEntity: Entity?
    @State var innerCylinderEntity: Entity?
    @State var touchEntity: Entity?
    @State var pointLightComponent: PointLightComponent?
    @State var timer: Timer?
    @State var time: Double = 0.0
    @State var rotationAngles: SIMD3<Float> = [0, 0, 0]
    @State var lastRotationUpdateTime = CACurrentMediaTime()
    @State var innerCylinderEntities: [Entity] = []
    @State var meshes: [LowLevelMesh] = []
    @State var currentPositionsArray: [[SIMD3<Float>]] = []
    @State var targetPositionsArray: [[SIMD3<Float>]] = []
    @State var innerCylinderRadius: Float?
    @State var beamHeight: Float?
    @State var wiggleAnimationProgress: Float = 0
    @State var isGestureActive: Bool = false

    let maxOpacity: Float = 1.0
    let minOpacity: Float = 0.5
    let numberOfInnerCylinders = 4
    let radialSegments = 16
    let heightSegments = 50
    let animationStepAmount: Float = 0.25
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let computePipeline: MTLComputePipelineState
    let signalGenerator = SignalGenerator()
    
    init() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = device.makeCommandQueue()!
        
        let library = device.makeDefaultLibrary()!
        let updateFunction = library.makeFunction(name: "updateCylinderWiggle")!
        self.computePipeline = try! device.makeComputePipelineState(function: updateFunction)
    }
    
    var body: some View {
        GeometryReader3D { proxy in
            RealityView { content in
                let size = content.convert(proxy.frame(in: .local), from: .local, to: .scene).extents
                print("size.y: \(size.y)")

                let boxSize = size.y * 0.1
                
                let cylinderSize = size.y-boxSize*2
                let capRadius = cylinderSize * 0.05
                
                let outerCylinderRadius = capRadius * 0.75
                let innerCylinderRadius = outerCylinderRadius * 0.25
                let touchEntityRadius = outerCylinderRadius * 3.0
                
                let outerCylinderEntity = await getCylinderEntity(height: cylinderSize, radius: outerCylinderRadius)
                
                let touchEntity = await getTouchEntity(radius: touchEntityRadius)
                let sortGroup = ModelSortGroup(depthPass: .postPass)
                
                for i in 0..<numberOfInnerCylinders {
                    let mesh = try! getInnerCylinderMesh()
                    let meshResource = try! await MeshResource(from: mesh)
                    let opacity = max(maxOpacity - Float(i) * (maxOpacity - minOpacity) / Float(numberOfInnerCylinders - 1), minOpacity)
                    let material = await generateAddMaterial(color: .init(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0), opacity: opacity)
                    let innerCylinderEntity = ModelEntity(mesh: meshResource, materials: [material])
                    
                    content.add(innerCylinderEntity)
                    innerCylinderEntity.components.set(OpacityComponent.init(opacity: 0.0))
                    innerCylinderEntity.components.set(ModelSortGroupComponent(group: sortGroup, order: 0))
                    
                    self.innerCylinderEntities.append(innerCylinderEntity)
                    self.meshes.append(mesh)
                    self.currentPositionsArray.append(generatePositions(height: cylinderSize, displacementRange: innerCylinderRadius))
                    self.targetPositionsArray.append(generatePositions(height: cylinderSize, displacementRange: innerCylinderRadius))
                    
                    innerCylinderEntity.applyRecursively { entity in
                        entity.components.set(ModelSortGroupComponent(group: sortGroup, order: 0))
                    }
                    innerCylinderEntity.components.set(OpacityComponent.init(opacity: 0.0))
                }
                
                content.add(outerCylinderEntity)
                
                touchEntity.components.set(OpacityComponent.init(opacity: 0.0))
                
                // We wrap touchEntity with a parent that has the constant offset to align the gesture location with touchEntity's transform
                let touchEntityWrapperForConstantOffset = Entity()
                touchEntityWrapperForConstantOffset.addChild(touchEntity)
                touchEntityWrapperForConstantOffset.transform.translation.y = size.y*0.5
                content.add(touchEntityWrapperForConstantOffset)
                
                
                touchEntityWrapperForConstantOffset.applyRecursively { entity in
                    entity.components.set(ModelSortGroupComponent(group: sortGroup, order: 1))
                }
                outerCylinderEntity.applyRecursively { entity in
                    entity.components.set(ModelSortGroupComponent(group: sortGroup, order: 0))
                }

                let boxTranslation = (size.y - boxSize) * 0.5
                
                let topCapEntity = getCapEntity(size: boxSize)
                topCapEntity.transform.translation.y = boxTranslation
                content.add(topCapEntity)
                
                let bottomCapEntity = getCapEntity(size: boxSize)
                bottomCapEntity.transform.translation.y = -boxTranslation
                content.add(bottomCapEntity)
                
                self.touchEntity = touchEntity
                self.outerCylinderEntity = outerCylinderEntity
                self.innerCylinderEntity = innerCylinderEntity
                
                self.innerCylinderRadius = innerCylinderRadius
                self.beamHeight = cylinderSize
            }
            .gesture(
                SpatialEventGesture(coordinateSpace: .local)
                    .onChanged { events in
                        guard let outerCylinderEntity, let touchEntity else { return }
                        isGestureActive = true
                        
                        outerCylinderEntity.components.set(OpacityComponent.init(opacity: 0.25))
                        
                        for innerCylinderEntity in self.innerCylinderEntities {
                            innerCylinderEntity.components.set(OpacityComponent.init(opacity: 1.0))
                        }
                        
                        
                        touchEntity.components.set(OpacityComponent.init(opacity: 1.0))
                        print("onChanged")
                        for event in events {
                            var y: Float = 0
                            switch event.kind {
                            case .touch, .indirectPinch:
                                y = Float(physicalMetrics.convert(event.location3D.y, to: .meters))
                                touchEntity.transform.translation.y = y * -1
                            case .directPinch:
                                print("directPinch")
                            case .pointer:
                                print("pointer")
                            @unknown default:
                                print("unknown default")
                            }

                            let minFreq: Float = 115
                            let maxFreq: Float = 250
                            let cylinderHeight: Float = beamHeight!
                            var normalizedY = (y + cylinderHeight / 2) / cylinderHeight
                            
                            // clamp for safety
                            let highestY: Float = 1.65
                            if normalizedY > highestY {
                                normalizedY = highestY
                            }
                            
                            let frequency = maxFreq - (maxFreq - minFreq) * normalizedY
                            signalGenerator.signalFrequency = Double(frequency)
                            signalGenerator.setFilterFrequency(Float(frequency*60))
                            signalGenerator.play()
                            
                            let pointLightComponent = PointLightComponent( cgColor: .init(red: 1, green: 1, blue: 1, alpha: 1), intensity: 2500, attenuationRadius: 0.1 )
                            touchEntity.components.set(pointLightComponent)
                        }
                    }
                    .onEnded { events in
                        guard let outerCylinderEntity, let touchEntity else { return }
                        isGestureActive = false
                        
                        outerCylinderEntity.components.set(OpacityComponent.init(opacity: 1.0))
                        for innerCylinderEntity in self.innerCylinderEntities {
                            innerCylinderEntity.components.set(OpacityComponent.init(opacity: 0.0))
                        }
                        
                        touchEntity.components.set(OpacityComponent.init(opacity: 0.0))
                        print("onEnded")
                        signalGenerator.stop()
                        
                        let pointLightComponent = PointLightComponent( cgColor: .init(red: 1, green: 1, blue: 1, alpha: 1), intensity: 0, attenuationRadius: 0.1 )
                        touchEntity.components.set(pointLightComponent)
                    }
            )
            .onAppear { startTimer() }
            .onDisappear { stopTimer() }
        }
    }
}

// MARK: Outer Glowing Cylinder (lightning)
extension LightBeamSynthView {
    func getCylinderEntity(includeCollision: Bool = true, height: Float, radius: Float = 0.01) async -> Entity {
        let entity = Entity()
        if includeCollision {
            let collisionRadius = radius*1.5
            let collisionComponent = CollisionComponent(shapes: [.generateBox(width: collisionRadius, height: height, depth: collisionRadius)])
            entity.components.set(collisionComponent)
            entity.components.set(InputTargetComponent())
        }
        
        // loop to create glow effect
        let count = 50
        for i in 0..<count {
            let fraction = Float(i) / Float(count)
            let newRadius = radius * (1.0 - fraction * 1.0)
            let opacity = pow(fraction, 2) // Quadratic exaggerates effect
            let childEntity = Entity()
            let modelComponent = await getCylinderModelComponent(height: height,radius: newRadius, opacity: opacity)
            childEntity.components.set(modelComponent)
            entity.addChild(childEntity)
        }
        
        return entity
    }
    
    func getCylinderModelComponent(height: Float, radius: Float, opacity: Float = 1.0) async -> ModelComponent {
        let resource = MeshResource.generateCylinder(height: height, radius: radius)
        let material = await generateAddMaterial(color: .init(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0), opacity: opacity) //
        let modelComponent = ModelComponent(mesh: resource, materials: [material])
        return modelComponent
    }
}

// MARK: Inner Cylinders (lightning)
extension LightBeamSynthView {
    struct CylinderWiggleParams {
        var radialSegments: Int32
        var heightSegments: Int32
        var radius: Float
        var height: Float
        var animationProgress: Float
    }
    
    struct VertexData {
        var position: SIMD3<Float> = .zero
        var normal: SIMD3<Float> = .zero
        
        static var vertexAttributes: [LowLevelMesh.Attribute] = [
            .init(semantic: .position, format: .float3, offset: MemoryLayout<Self>.offset(of: \.position)!),
            .init(semantic: .normal, format: .float3, offset: MemoryLayout<Self>.offset(of: \.normal)!),
        ]

        static var vertexLayouts: [LowLevelMesh.Layout] = [
            .init(bufferIndex: 0, bufferStride: MemoryLayout<Self>.stride)
        ]

        static var descriptor: LowLevelMesh.Descriptor {
            var desc = LowLevelMesh.Descriptor()
            desc.vertexAttributes = VertexData.vertexAttributes
            desc.vertexLayouts = VertexData.vertexLayouts
            desc.indexType = .uint32
            return desc
        }
    }
    
    func getInnerCylinderMesh() throws -> LowLevelMesh {
        let vertexCount = (radialSegments + 1) * (heightSegments + 1)
        let indexCount = radialSegments * heightSegments * 6
        
        var desc = VertexData.descriptor
        desc.vertexCapacity = vertexCount
        desc.indexCapacity = indexCount
        
        return try LowLevelMesh(descriptor: desc)
    }
    
    func updateInnerCylinderMesh(_ mesh: LowLevelMesh, height: Float, radius: Float, currentPositions: [SIMD3<Float>], targetPositions: [SIMD3<Float>]) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        let vertexBuffer = mesh.replace(bufferIndex: 0, using: commandBuffer)
        let indexBuffer = mesh.replaceIndices(using: commandBuffer)
        
        let currentPositionsBuffer = device.makeBuffer(bytes: currentPositions, length: MemoryLayout<SIMD3<Float>>.stride * currentPositions.count, options: [])
        let targetPositionsBuffer = device.makeBuffer(bytes: targetPositions, length: MemoryLayout<SIMD3<Float>>.stride * targetPositions.count, options: [])
        
        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.setBuffer(vertexBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(indexBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(currentPositionsBuffer, offset: 0, index: 2)
        computeEncoder.setBuffer(targetPositionsBuffer, offset: 0, index: 3)
        
        var params = CylinderWiggleParams(
            radialSegments: Int32(radialSegments),
            heightSegments: Int32(heightSegments),
            radius: radius,
            height: height,
            animationProgress: wiggleAnimationProgress
        )
        computeEncoder.setBytes(&params, length: MemoryLayout<CylinderWiggleParams>.size, index: 4)
        
        let threadsPerGrid = MTLSize(width: (radialSegments + 1) * (heightSegments + 1), height: 1, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: 64, height: 1, depth: 1)
        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        computeEncoder.endEncoding()
        commandBuffer.commit()
        
        let meshBounds = BoundingBox(min: [-radius*2, -height/2, -radius*2], max: [radius*2, height/2, radius*2])
        mesh.parts.replaceAll([
            LowLevelMesh.Part(
                indexCount: radialSegments * heightSegments * 6,
                topology: .triangle,
                bounds: meshBounds
            )
        ])
    }
}

// MARK: Touch Entity (Gesture Location)
extension LightBeamSynthView {
    func getTouchEntity(radius: Float) async -> Entity {
        let sphereEntity = Entity()
        
        // loop to create glow effect
        let numSpheres = 50
        for i in 0..<numSpheres {
            let fraction = Float(i) / Float(numSpheres)
            let sphereRadius = radius * (1.0 - fraction * 1.0)
            let opacity = pow(fraction, 4) // Quadratic exaggerates effect
            let sphere = Entity()
            let modelComponent = await getTouchModelComponent(radius: sphereRadius, opacity: opacity)
            sphere.components.set(modelComponent)
            sphereEntity.addChild(sphere)
        }
        
        // Add spark emitter
        let sparkEmitter = createSparkEmitter(radius: radius*0.25)
        sphereEntity.addChild(sparkEmitter)
        
        self.pointLightComponent = pointLightComponent
        
        return sphereEntity
    }
    
    func getTouchModelComponent(radius: Float, opacity: Float) async -> ModelComponent {
        var material = await generateAddMaterial(color: .init(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0), opacity: opacity)
        material.faceCulling = .back

        let sphereMesh = try! MeshResource.generateSpecificSphere(radius: radius, latitudeBands: 8, longitudeBands: 8)
        return ModelComponent(mesh: sphereMesh, materials: [material])
    }
    
    func createSparkEmitter(radius: Float) -> Entity {
        let sparkEntity = Entity()
        var emitterComponent = ParticleEmitterComponent()
        emitterComponent.emitterShape = .sphere
        emitterComponent.emitterShapeSize = .init(x: radius, y: radius, z: radius)
        emitterComponent.birthLocation = .surface
        emitterComponent.birthDirection = .normal
        emitterComponent.mainEmitter.birthRate = 500 // Increase for more sparks
        emitterComponent.mainEmitter.lifeSpan = 0.3 // Short lifespan for quick sparks
        emitterComponent.speed = 0.375 // Moderate speed
        emitterComponent.speedVariation = 0.125 // Add some variation to the speed
        let mainEmitterSize = radius*0.05
        emitterComponent.mainEmitter.size = mainEmitterSize // Small size for spark-like appearance
        emitterComponent.mainEmitter.sizeVariation = mainEmitterSize*0.5
        emitterComponent.mainEmitter.color = .evolving(
            start: .random(a: .init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
                           b: .init(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0)),
            end: .random(a: .init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0),
                         b: .init(red: 0.5, green: 0.5, blue: 1.0, alpha: 0.0))
        )
        emitterComponent.mainEmitter.opacityCurve = .quickFadeInOut
        emitterComponent.mainEmitter.spreadingAngle = .pi / 4 // 45-degree spread
        emitterComponent.mainEmitter.blendMode = .additive // For a glowing effect
        emitterComponent.mainEmitter.angularSpeed = 10.0
        emitterComponent.mainEmitter.angularSpeedVariation = 5.0
        emitterComponent.mainEmitter.isLightingEnabled = true
        emitterComponent.mainEmitter.acceleration = SIMD3<Float>(0, -2.0, 0)
        sparkEntity.components[ParticleEmitterComponent.self] = emitterComponent
        return sparkEntity
    }
}

// MARK: Top and Bottom Cap
extension LightBeamSynthView {
    func getCapEntity(size: Float) -> Entity {
        let entity = Entity()
        let mesh = MeshResource.generateCylinder(height: size, radius: size*0.5)
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = .gray
        material.metallic = 1.0
        material.roughness = 0.0
        let modelComponent = ModelComponent(mesh: mesh, materials: [material])
        entity.components.set(modelComponent)
        return entity
    }
}

// MARK: Laser Beam Add Material
extension LightBeamSynthView {
    func generateAddMaterial(color: UIColor, opacity: Float = 1.0) async -> UnlitMaterial {
        var descriptor = UnlitMaterial.Program.Descriptor()
        descriptor.blendMode = .add
        let prog = await UnlitMaterial.Program(descriptor: descriptor)
        var material = UnlitMaterial(program: prog)
        material.color = UnlitMaterial.BaseColor(tint: color)
        material.blending = .transparent(opacity: .init(floatLiteral: opacity))

        return material
    }
}

// MARK: Animation
extension LightBeamSynthView {
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1/120.0, repeats: true) { _ in
            guard isGestureActive else { return } // don't process unless needed
            stepTouchEntityRotation()
            stepInnerCylinderAnimation()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func stepTouchEntityRotation() {
        let currentTime = CACurrentMediaTime()
        let frameDuration = currentTime - lastRotationUpdateTime
        self.time += frameDuration
        
        // Rotate along all axis at different rates for a wonky rotation effect
        rotationAngles.x += Float(frameDuration * 3.0)
        rotationAngles.y += Float(frameDuration * 1.4)
        rotationAngles.z += Float(frameDuration * 0.9)
        
        let rotationX = simd_quatf(angle: rotationAngles.x, axis: [1, 0, 0])
        let rotationY = simd_quatf(angle: rotationAngles.y, axis: [0, 1, 0])
        let rotationZ = simd_quatf(angle: rotationAngles.z, axis: [0, 0, 1])
        touchEntity?.transform.rotation = rotationX * rotationY * rotationZ
        
        lastRotationUpdateTime = currentTime
    }
    
    func stepInnerCylinderAnimation() {
        if let beamHeight, let innerCylinderRadius {
            wiggleAnimationProgress += animationStepAmount
            
            if self.wiggleAnimationProgress >= 1 {
                for i in 0..<self.innerCylinderEntities.count {
                    self.currentPositionsArray[i] = self.targetPositionsArray[i]
                    self.targetPositionsArray[i] = self.generatePositions(height: beamHeight, displacementRange: innerCylinderRadius)
                }
                self.wiggleAnimationProgress = 0
            }
            
            for i in 0..<self.innerCylinderEntities.count {
                self.updateInnerCylinderMesh(
                    self.meshes[i],
                    height: beamHeight,
                    radius: innerCylinderRadius*0.25,
                    currentPositions: self.currentPositionsArray[i],
                    targetPositions: self.targetPositionsArray[i]
                )
            }
            
        }
    }
    
    // for inner cylinder positions (lightning)
    func generatePositions(height: Float, displacementRange: Float) -> [SIMD3<Float>] {
        var positions: [SIMD3<Float>] = []
        let startPosition = SIMD3<Float>(0, -height/2, 0)
        let endPosition = SIMD3<Float>(0, height/2, 0)
        
        for y in 0...heightSegments {
            let progress = Float(y) / Float(heightSegments)
            var centerPosition = mix(startPosition, endPosition, t: progress)
            
            if y != 0 && y != heightSegments {
                centerPosition.x += Float.random(in: -displacementRange...displacementRange)
                centerPosition.z += Float.random(in: -displacementRange...displacementRange)
            }
            
            positions.append(centerPosition)
        }
        
        return positions
    }
}

// MARK: MeshResource+generateSpecificSphere
extension MeshResource {
    static func generateSpecificSphere(radius: Float, latitudeBands: Int = 10, longitudeBands: Int = 10) throws -> MeshResource {
        let vertexCount = (latitudeBands + 1) * (longitudeBands + 1)
        let indexCount = latitudeBands * longitudeBands * 6
        
        var desc = MyVertexWithNormal.descriptor
        desc.vertexCapacity = vertexCount
        desc.indexCapacity = indexCount
        
        let mesh = try LowLevelMesh(descriptor: desc)

        mesh.withUnsafeMutableBytes(bufferIndex: 0) { rawBytes in
            let vertices = rawBytes.bindMemory(to: MyVertexWithNormal.self)
            var vertexIndex = 0
            
            for latNumber in 0...latitudeBands {
                let theta = Float(latNumber) * Float.pi / Float(latitudeBands)
                let sinTheta = sin(theta)
                let cosTheta = cos(theta)
                
                for longNumber in 0...longitudeBands {
                    let phi = Float(longNumber) * 2 * Float.pi / Float(longitudeBands)
                    let sinPhi = sin(phi)
                    let cosPhi = cos(phi)
                    
                    let x = cosPhi * sinTheta
                    let y = cosTheta
                    let z = sinPhi * sinTheta
                    let position = SIMD3<Float>(x, y, z) * radius
                    let normal = -SIMD3<Float>(x, y, z).normalized()
                    vertices[vertexIndex] = MyVertexWithNormal(position: position, normal: normal)
                    vertexIndex += 1
                }
            }
        }
        
        mesh.withUnsafeMutableIndices { rawIndices in
            let indices = rawIndices.bindMemory(to: UInt32.self)
            var index = 0
            
            for latNumber in 0..<latitudeBands {
                for longNumber in 0..<longitudeBands {
                    let first = (latNumber * (longitudeBands + 1)) + longNumber
                    let second = first + longitudeBands + 1
                    
                    indices[index] = UInt32(first)
                    indices[index + 1] = UInt32(second)
                    indices[index + 2] = UInt32(first + 1)
                    
                    indices[index + 3] = UInt32(second)
                    indices[index + 4] = UInt32(second + 1)
                    indices[index + 5] = UInt32(first + 1)
                    
                    index += 6
                }
            }
        }
        
        let meshBounds = BoundingBox(min: [-radius, -radius, -radius], max: [radius, radius, radius])
        mesh.parts.replaceAll([
            LowLevelMesh.Part(
                indexCount: indexCount,
                topology: .triangle,
                bounds: meshBounds
            )
        ])
        return try MeshResource(from: mesh)
    }
}

extension Entity {
    func applyRecursively(_ block: (Entity) -> Void) {
        block(self)
        for child in children {
            child.applyRecursively(block)
        }
    }
}

// MARK: MyVertexWithNormal
struct MyVertexWithNormal {
    var position: SIMD3<Float> = .zero
    var normal: SIMD3<Float> = .zero
    
    static var vertexAttributes: [LowLevelMesh.Attribute] = [
        .init(semantic: .position, format: .float3, offset: MemoryLayout<Self>.offset(of: \.position)!),
        .init(semantic: .normal, format: .float3, offset: MemoryLayout<Self>.offset(of: \.normal)!),
    ]

    static var vertexLayouts: [LowLevelMesh.Layout] = [
        .init(bufferIndex: 0, bufferStride: MemoryLayout<Self>.stride)
    ]

    static var descriptor: LowLevelMesh.Descriptor {
        var desc = LowLevelMesh.Descriptor()
        desc.vertexAttributes = MyVertexWithNormal.vertexAttributes
        desc.vertexLayouts = MyVertexWithNormal.vertexLayouts
        desc.indexType = .uint32
        return desc
    }
}

// MARK: Audio Signal Generator
class SignalGenerator {
    var signalFrequency: Double = 250.0
    var isPlaying = false
    var noiseVolume: Float = 0.375
    var filterFrequency: Float = 1000.0
    var engine = AVAudioEngine()
    var signalNode: AVAudioSourceNode?
    var noiseNode: AVAudioSourceNode?
    var lowPassFilter: AVAudioUnitEQ?
    var runningPhase: Double = 0.0
    
    init() {
        configureAudioSession()
        setupAudio()
    }
    
    private func setupAudio() {
        let mainMixer = engine.mainMixerNode
        let output = engine.outputNode
        let format = output.inputFormat(forBus: 0)

        let signalNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            var phase: Double = self.runningPhase
            let phaseIncrement = self.signalFrequency / format.sampleRate
            
            for frame in 0..<Int(frameCount) {
                // Saw wave generation
                let value = 2 * (phase - floor(0.5 + phase))
                
                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = Float(value) * 0.3 // Reduced volume
                }
                
                phase += phaseIncrement
                if phase >= 1.0 {
                    phase -= 1.0
                }
            }
            self.runningPhase = phase
            return noErr
        }
        signalNode.volume = 0.0
        
        // Create a noise generator node
        let noiseNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let noise = self.generatePinkNoise() * self.noiseVolume
                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = noise
                }
            }
            return noErr
        }
        noiseNode.volume = 0.0
        
        let lowPassFilter = AVAudioUnitEQ(numberOfBands: 1)
        lowPassFilter.bands[0].filterType = .lowPass
        lowPassFilter.bands[0].frequency = 1000 // Cutoff frequency in Hz
        lowPassFilter.bands[0].bandwidth = 1.0
        lowPassFilter.bands[0].bypass = false
        
        // Create a mixer node to combine the saw wave and noise
        let mixerNode = AVAudioMixerNode()
        
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.largeHall2)
        reverbNode.wetDryMix = 50
        
        let delayUnit = AVAudioUnitDelay()
        delayUnit.wetDryMix = 30
        delayUnit.delayTime = 0.25
        delayUnit.feedback = 30
        delayUnit.lowPassCutoff = 1000
        engine.attach(delayUnit)
        
        engine.attach(signalNode)
        engine.attach(noiseNode)
        engine.attach(lowPassFilter)
        engine.attach(mixerNode)
        engine.attach(reverbNode)
        
        engine.connect(signalNode, to: mixerNode, format: format)
        engine.connect(noiseNode, to: mixerNode, format: format)
        engine.connect(mixerNode, to: lowPassFilter, format: format)
        engine.connect(lowPassFilter, to: reverbNode, format: format)
        engine.connect(reverbNode, to: delayUnit, format: format)
        engine.connect(delayUnit, to: mainMixer, format: format)
        engine.connect(mainMixer, to: output, format: format)
        
        do {
            try engine.start()
        } catch {
            print("Could not start engine: \(error.localizedDescription)")
        }

        self.signalNode = signalNode
        self.noiseNode = noiseNode
        self.lowPassFilter = lowPassFilter
    }
    
    func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setIntendedSpatialExperience(.bypassed)
            try audioSession.setActive(true)
        } catch {
            print(error)
        }
    }

    func play() {
        guard !isPlaying else { return }
        signalNode?.volume = 1.0
        noiseNode?.volume = noiseVolume
        isPlaying = true
    }
    
    func setFilterFrequency(_ newFrequency: Float) {
        filterFrequency = newFrequency
        lowPassFilter?.bands[0].frequency = filterFrequency
    }

    func stop() {
        signalNode?.volume = 0.0
        noiseNode?.volume = 0.0
        isPlaying = false
    }
    
    private func generateWhiteNoise() -> Float {
        return Float.random(in: -1...1)
    }

    private var pinkNoiseBuffer = [Float](repeating: 0, count: 7)

    private func generatePinkNoise() -> Float {
        let white = generateWhiteNoise()
        pinkNoiseBuffer[0] = 0.99886 * pinkNoiseBuffer[0] + white * 0.0555179
        pinkNoiseBuffer[1] = 0.99332 * pinkNoiseBuffer[1] + white * 0.0750759
        pinkNoiseBuffer[2] = 0.96900 * pinkNoiseBuffer[2] + white * 0.1538520
        pinkNoiseBuffer[3] = 0.86650 * pinkNoiseBuffer[3] + white * 0.3104856
        pinkNoiseBuffer[4] = 0.55000 * pinkNoiseBuffer[4] + white * 0.5329522
        pinkNoiseBuffer[5] = -0.7616 * pinkNoiseBuffer[5] - white * 0.0168980
        pinkNoiseBuffer[6] = white * 0.115926
        return pinkNoiseBuffer.reduce(0, +) * 0.11
    }
}
