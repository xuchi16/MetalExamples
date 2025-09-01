// Created by Chester for Raybreak in 2025

import MetalKit
import UIKit

enum Colors {
    static let wenderlichGreen = MTLClearColor(red: 0.0, green: 0.4, blue: 0.21, alpha: 1.0)
}

class ViewController: UIViewController {
    // Story board 中创建的 MTKView
    var metalView: MTKView {
        return view as! MTKView
    }

    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!

    override func viewDidLoad() {
        super.viewDidLoad()

        metalView.device = MTLCreateSystemDefaultDevice()
        device = metalView.device
        commandQueue = device.makeCommandQueue()

        metalView.clearColor = Colors.wenderlichGreen
        metalView.delegate = self
    }
}

extension ViewController: MTKViewDelegate {
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
