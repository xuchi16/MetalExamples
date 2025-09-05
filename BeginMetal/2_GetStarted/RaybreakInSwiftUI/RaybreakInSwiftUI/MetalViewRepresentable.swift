// Created by Chester for RaybreakInSwiftUI in 2025

import MetalKit
import SwiftUI

enum Colors {
    static let wenderlichGreen = MTLClearColor(red: 0.0, green: 0.4, blue: 0.21, alpha: 1.0)
}

struct MetalView: UIViewControllerRepresentable {
    // 创建 UIViewController
    func makeUIViewController(context: Context) -> MetalViewController {
        return MetalViewController()
    }

    // 更新 UIViewController（此处无需额外更新）
    func updateUIViewController(_ uiViewController: MetalViewController, context: Context) {
        // 可根据需要更新视图控制器
    }
}

class MetalViewController: UIViewController {
    var metalView: MTKView!
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!

    override func viewDidLoad() {
        super.viewDidLoad()

        // 程序化地初始化 MTKView
        metalView = MTKView(frame: view.bounds) // 此前从 story board 获取
        view.addSubview(metalView)

        // 设置 Metal
        metalView.device = MTLCreateSystemDefaultDevice()
        device = metalView.device
        metalView.clearColor = Colors.wenderlichGreen
        metalView.delegate = self

        commandQueue = device.makeCommandQueue()
    }
}

extension MetalViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        // 每一帧都会调用
        // 首先要获取到调用时的 drawable 和 descriptor
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor
        else {
            return
        }

        let commandBuffer = commandQueue.makeCommandBuffer()

        let commandEncooder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)
        commandEncooder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
