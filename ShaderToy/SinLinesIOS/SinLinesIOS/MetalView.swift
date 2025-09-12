// Created by Chester for SinLinesIOS in 2025

import MetalKit
import simd
import SwiftUI

struct MetalView: UIViewControllerRepresentable {
    @Binding var selectedShader: ShaderType

    // 创建 UIViewController
    func makeUIViewController(context: Context) -> MetalViewController {
        let viewController = MetalViewController()
        viewController.selectedShader = selectedShader
        return viewController
    }

    // 更新 UIViewController（此处无需额外更新）
    func updateUIViewController(_ uiViewController: MetalViewController, context: Context) {
        uiViewController.selectedShader = selectedShader
        uiViewController.updatePipelineState()
    }
}

class MetalViewController: UIViewController {
    var metalView: MTKView!
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer?

    var selectedShader: ShaderType = .sineWave {
        didSet {
            if oldValue != selectedShader {
                updatePipelineState()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetalView()
        setupVertexBuffer()
        updatePipelineState()
    }

    private func setupMetalView() {
        metalView = MTKView(frame: view.bounds)
        view.addSubview(metalView)
        metalView.device = MTLCreateSystemDefaultDevice()
        device = metalView.device
        metalView.delegate = self
        commandQueue = device.makeCommandQueue()
    }

    private func setupVertexBuffer() {
        // 全屏四边形顶点数据 (位置 + 纹理坐标)
        let vertices: [Float] = [
            // 位置x, 位置y, 纹理u, 纹理v
            -1, -1, 0, 1, // 左下
            1, -1, 1, 1, // 右下
            -1, 1, 0, 0, // 左上
            1, 1, 1, 0 // 右上
        ]

        let size = vertices.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertices, length: size, options: [])
    }

    func updatePipelineState() {
        do {
            pipelineState = try buildPipelineState(for: selectedShader.fragmentShaderName)
        } catch {
            print("Error creating pipeline state: \(error.localizedDescription)")
        }
    }

    private func buildPipelineState(for fragmentShaderName: String) throws -> MTLRenderPipelineState {
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: fragmentShaderName)
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<VertexIn>.stride

        pipelineDescriptor.vertexDescriptor = vertexDescriptor

        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}

extension MetalViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        // 每一帧都会调用
        // 首先要获取到调用时的 drawable 和 descriptor
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            return
        }

        // 放置常用参数
        var uniforms = ShaderUniforms(
            iResolution: SIMD4<Float>(Float(view.drawableSize.width),
                                      Float(view.drawableSize.height),
                                      0, 0),
            iTime: Float(CACurrentMediaTime())
        )

        // 绘制
        commandEncoder.setRenderPipelineState(pipelineState)
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.setFragmentBytes(&uniforms,
                                        length: MemoryLayout<ShaderUniforms>.stride,
                                        index: 0)

        // 绘制全屏四边形
        commandEncoder.drawPrimitives(type: .triangleStrip,
                                      vertexStart: 0,
                                      vertexCount: 4)

        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
