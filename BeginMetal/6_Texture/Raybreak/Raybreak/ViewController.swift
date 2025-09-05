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

    var renderer: Renderer!

    override func viewDidLoad() {
        super.viewDidLoad()

        // 设置 Metal
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        metalView.device = device
        metalView.clearColor = Colors.wenderlichGreen

        // 初始化 Renderer 并设置为 MTKView 的代理
        renderer = Renderer(device: device)
        renderer?.scene = GameScene(device: device, size: view.bounds.size)
        metalView.delegate = renderer
    }
}
